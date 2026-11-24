<?php
/**
 * Plugin Name: AKE Delivery API
 * Version: 0.1.0
 */
defined('ABSPATH') || exit;
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
            $orders=wc_get_orders(['limit'=>100,'status'=>['processing','on-hold'],'meta_query'=>[['key'=>'_ake_courier_id','value'=>get_current_user_id(),'compare'=>'=']]]);
            $out=[];
            foreach($orders as $o){
                if((int)$o->get_meta('_ake_courier_id')!==get_current_user_id()) continue;
                $lat=$o->get_meta('_ake_lat'); $lng=$o->get_meta('_ake_lng');
                if(!is_numeric($lat)||!is_numeric($lng)) continue;
                $out[]=['id'=>$o->get_id(),'lat'=>(float)$lat,'lng'=>(float)$lng,'address'=>$o->get_shipping_address_1() ?: $o->get_billing_address_1()];
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
 foreach(wc_get_orders(['customer_id'=>get_current_user_id(),'limit'=>50,'status'=>['pending','on-hold']]) as $o){
 if((int)$o->get_customer_id()!==get_current_user_id()) continue;
 $out[]=['id'=>$o->get_id(),'number'=>$o->get_order_number(),'status'=>$o->get_status()];
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
 $address=sanitize_text_field((string)$r->get_param('address'));
 $lat=$r->get_param('lat'); $lng=$r->get_param('lng');
 if(!is_array($items)||!count($items)||count($items)>50||!$address||!is_numeric($lat)||!is_numeric($lng)||abs((float)$lat)>90||abs((float)$lng)>180) return new WP_Error('invalid','Invalid request',['status'=>400]);
 $products=[];
 foreach($items as $id=>$qty){
 if(!ctype_digit((string)$id)||!is_int($qty)||$qty<1||$qty>1000) return new WP_Error('invalid_item','Invalid item',['status'=>400]);
 $p=wc_get_product((int)$id);
 if(!$p||!$p->is_type('simple')||!$p->is_purchasable()||!$p->is_in_stock()||!$p->has_enough_stock($qty)||($p->is_sold_individually()&&$qty>1)) return new WP_Error('unavailable_item','Product unavailable',['status'=>409]);
 $products[]=[$p,$qty];
 }
 $o=null;
 try {
 $o=new WC_Order();
 $o->set_customer_id(get_current_user_id());
 $o->set_created_via('ake-app-request');
 $o->set_shipping_address_1($address);
 $o->set_shipping_country('IR');
 $o->set_billing_country('IR');
 foreach($products as [$p,$qty]) $o->add_product($p,$qty);
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
