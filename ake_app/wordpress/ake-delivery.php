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
