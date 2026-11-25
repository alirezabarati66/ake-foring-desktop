<?php
/**
 * Plugin Name: AKE Delivery API
 * Version: 0.2.0
 */
defined('ABSPATH') || exit;
// Digits REST API 2.3 omits user_id from a successful registration response.
// Its create_user handler then passes 0 to digrest_create_token(), returning
// "Error: Unexpected user". Restore the user ID expected by that handler.
add_filter('digits_user_created_response', function($data, $user_id) {
    if (is_array($data) && !empty($data['success']) && is_array($data['data'] ?? null)) {
        $data['data']['user_id'] = (int) $user_id;
    }
    return $data;
}, 10, 2);

add_action('rest_api_init', function(){
    register_rest_route('ake/v1','/orders/(?P<id>\d+)/location',[
        'methods'=>'POST',
        'permission_callback'=>function(){return is_user_logged_in();},
        'callback'=>function($r){
            if(!function_exists('wc_get_order')) return new WP_Error('unavailable','WooCommerce unavailable',['status'=>503]);
            $o=wc_get_order((int)$r['id']);
            if(!$o || !$o->get_customer_id() || (int)$o->get_customer_id()!==get_current_user_id()) return new WP_Error('forbidden','Forbidden',['status'=>403]);
            if(!$o->has_status(['pending','on-hold'])) return new WP_Error('locked','Order location locked',['status'=>409]);
            $lat=$r->get_param('lat'); $lng=$r->get_param('lng');
            if(!is_numeric($lat)||!is_numeric($lng)||abs((float)$lat)>90||abs((float)$lng)>180) return new WP_Error('invalid','Invalid coordinates',['status'=>400]);
            $o->update_meta_data('_ake_lat',(float)$lat);
            $o->update_meta_data('_ake_lng',(float)$lng);
            $o->save();
            return ['saved'=>true];
        }
    ]);
    register_rest_route('ake/v1','/missions',[
        'methods'=>'GET',
        'permission_callback'=>function(){return is_user_logged_in() && current_user_can('ake_deliver_orders');},
        'callback'=>function(){
            if(!function_exists('wc_get_orders')) return new WP_Error('unavailable','WooCommerce unavailable',['status'=>503]);
            $orders=wc_get_orders(['limit'=>100,'status'=>['pending','on-hold','processing'],'meta_query'=>[['key'=>'_ake_courier_id','value'=>get_current_user_id(),'compare'=>'=']]]);
            $out=[];
            foreach($orders as $o){
                if((int)$o->get_meta('_ake_courier_id')!==get_current_user_id()) continue;
                $lat=$o->get_meta('_ake_lat'); $lng=$o->get_meta('_ake_lng');
                if(!is_numeric($lat)||!is_numeric($lng)) continue;
                $out[]=['id'=>$o->get_id(),'number'=>$o->get_order_number(),'lat'=>(float)$lat,'lng'=>(float)$lng,'address'=>$o->get_shipping_address_1() ?: $o->get_billing_address_1(),'customer'=>$o->get_formatted_billing_full_name(),'phone'=>$o->get_billing_phone(),'status'=>$o->get_status(),'delivery_status'=>$o->get_meta('_ake_delivery_status') ?: 'assigned','total'=>$o->get_formatted_order_total()];
            }
            return rest_ensure_response($out);
        }
    ]);
});
register_activation_hook(__FILE__,function(){add_role('ake_courier','AKE Courier',['read'=>true,'ake_deliver_orders'=>true]);});

add_action('rest_api_init',function(){
 register_rest_route('ake/v1','/me',[
 'methods'=>'GET','permission_callback'=>function(){return is_user_logged_in();},
 'callback'=>function(){ $u=wp_get_current_user(); return ['id'=>$u->ID,'name'=>$u->display_name,'courier'=>current_user_can('ake_deliver_orders')]; }
 ]);
 register_rest_route('ake/v1','/orders',[
 'methods'=>'GET','permission_callback'=>function(){return is_user_logged_in();},
 'callback'=>function(){
 if(!function_exists('wc_get_orders')) return new WP_Error('unavailable','WooCommerce unavailable',['status'=>503]);
 $out=[];
 foreach(wc_get_orders(['customer_id'=>get_current_user_id(),'limit'=>50,'orderby'=>'date','order'=>'DESC']) as $o){
 if((int)$o->get_customer_id()!==get_current_user_id()) continue;
 $out[]=['id'=>$o->get_id(),'number'=>$o->get_order_number(),'status'=>$o->get_status(),'date'=>$o->get_date_created() ? $o->get_date_created()->date_i18n('Y/m/d H:i') : '','total'=>$o->get_formatted_order_total(),'delivery_status'=>$o->get_meta('_ake_delivery_status') ?: 'waiting'];
 }
 return $out;
 }
 ]);
});
add_action('woocommerce_admin_order_data_after_shipping_address',function($order){
 if(!current_user_can('manage_woocommerce')) return;
 wp_nonce_field('ake_assign_'.$order->get_id(),'ake_assign_nonce');
 $couriers=get_users(['role'=>'ake_courier','fields'=>['ID','display_name']]);
 echo '<p><label for="ake_courier_id">AKE Courier</label><select name="ake_courier_id" id="ake_courier_id"><option value="0">Unassigned</option>';
 foreach($couriers as $u) printf('<option value="%d" %s>%s</option>',$u->ID,selected((int)$order->get_meta('_ake_courier_id'),$u->ID,false),esc_html($u->display_name));
 echo '</select></p>';
});
add_action('woocommerce_process_shop_order_meta',function($id){
 if(!current_user_can('manage_woocommerce')||!isset($_POST['ake_assign_nonce'],$_POST['ake_courier_id'])||!wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['ake_assign_nonce'])),'ake_assign_'.$id)) return;
 $uid=absint($_POST['ake_courier_id']);
 if($uid && !user_can($uid,'ake_deliver_orders')) return;
 $o=wc_get_order($id); if(!$o) return;
 $o->update_meta_data('_ake_courier_id',$uid); $o->save();
});

add_action('rest_api_init',function(){
 register_rest_route('ake/v1','/order-request',[
 'methods'=>'POST','permission_callback'=>function(){return is_user_logged_in();},
 'callback'=>function($r){
 if(!function_exists('wc_create_order')) return new WP_Error('unavailable','WooCommerce unavailable',['status'=>503]);
 $items=$r->get_param('items');
 $options=$r->get_param('options');
 if(!is_array($options)) $options=[];
 $address=sanitize_text_field((string)$r->get_param('address'));
 $lat=$r->get_param('lat'); $lng=$r->get_param('lng');
 if(!is_array($items)||!count($items)||count($items)>50||!$address||!is_numeric($lat)||!is_numeric($lng)||abs((float)$lat)>90||abs((float)$lng)>180) return new WP_Error('invalid','Invalid request',['status'=>400]);
 $products=[];
 foreach($items as $id=>$qty){
 if(!ctype_digit((string)$id)||!is_int($qty)||$qty<1||$qty>1000) return new WP_Error('invalid_item','Invalid item',['status'=>400]);
 $p=wc_get_product((int)$id);
 if(!$p || (!$p->is_type('simple') && !$p->is_type('variation')) || !$p->is_purchasable() || !$p->is_in_stock() || !$p->has_enough_stock($qty) || ($p->is_sold_individually() && $qty>1)) return new WP_Error('unavailable_item','Product unavailable',['status'=>409]);
 if($p->is_type('variation')) {
  $parent=wc_get_product($p->get_parent_id());
  if(!$parent || !$parent->is_type('variable')) return new WP_Error('invalid_variation','Invalid product variation',['status'=>400]);
 }
 $products[]=[$p,$qty];
 }
 $o=null;
 try {
 $o=new WC_Order();
 $o->set_customer_id(get_current_user_id());
 $o->set_created_via('ake-app-request');
 $customer=get_userdata(get_current_user_id());
 $phone=get_user_meta(get_current_user_id(),'billing_phone',true);
 if(!$phone) $phone=get_user_meta(get_current_user_id(),'digits_phone',true);
 if(!$phone) $phone=get_user_meta(get_current_user_id(),'digits_phone_no',true);
 $customer_name=$customer ? ($customer->first_name ?: $customer->display_name) : '';
 $o->set_billing_first_name($customer_name);
 $o->set_billing_phone($phone);
 $o->set_billing_email($customer ? $customer->user_email : '');
 $o->set_billing_address_1($address);
 $o->set_shipping_first_name($customer_name);
 $o->set_shipping_address_1($address);
 $o->set_shipping_country('IR');
 $o->set_billing_country('IR');
 foreach($products as [$p,$qty]) {
   $item_id=$o->add_product($p,$qty);
   $chosen=$options[(string)$p->get_id()] ?? [];
   if($item_id && is_array($chosen)) {
    $item=$o->get_item($item_id);
    foreach($chosen as $attribute=>$value) {
     $attribute=sanitize_text_field((string)$attribute);
     $value=sanitize_text_field((string)$value);
     if($attribute!=='' && $value!=='' && strlen($attribute)<=100 && strlen($value)<=150) {
      $item->add_meta_data('مشخصه انتخابی: '.$attribute,$value,true);
     }
    }
    $item->save();
   }
  }
 $o->update_meta_data('_ake_lat',(float)$lat);
 $o->update_meta_data('_ake_lng',(float)$lng);
 $o->update_meta_data('_ake_requires_shipping_quote','yes');
 $o->calculate_totals();
 $o->set_status('pending');
 $o->save();
 return ['id'=>$o->get_id(),'status'=>'pending','requires_review'=>true];
 } catch(Throwable $e){
 if($o && $o->get_id()) $o->delete(true);
 return new WP_Error('order_error','Unable to create order',['status'=>500]);
 }
 }
 ]);
});

add_action('rest_api_init',function(){
 register_rest_route('ake/v1','/missions/(?P<id>\\d+)/status',[
  'methods'=>'POST',
  'permission_callback'=>function(){return is_user_logged_in() && current_user_can('ake_deliver_orders');},
  'callback'=>function($request){
   if(!function_exists('wc_get_order')) return new WP_Error('unavailable','WooCommerce unavailable',['status'=>503]);
   $order=wc_get_order((int)$request['id']);
   if(!$order || (int)$order->get_meta('_ake_courier_id')!==get_current_user_id()) return new WP_Error('forbidden','Mission not assigned to this courier',['status'=>403]);
   $status=sanitize_key((string)$request->get_param('status'));
   $allowed=['accepted','picked_up','out_for_delivery','delivered'];
   if(!in_array($status,$allowed,true)) return new WP_Error('invalid_status','Invalid delivery status',['status'=>400]);
   $order->update_meta_data('_ake_delivery_status',$status);
   $order->update_meta_data('_ake_delivery_status_updated',current_time('mysql'));
   if($status==='delivered') $order->add_order_note(__('Delivery marked as delivered from AKE Courier App.','ake'));
   $order->save();
   return ['saved'=>true,'status'=>$status,'order_id'=>$order->get_id()];
  }
 ]);
});
