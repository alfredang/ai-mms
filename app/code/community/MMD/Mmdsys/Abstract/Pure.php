<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Abstract_Pure
{
    public function __call( $method , array $args )
    {
        return $this;
    }
    
    public function __set( $key , $value )
    {
        
    }
    
    public function __get( $key )
    {
        return $this;
    }
    
    public function __isset( $key )
    {
        
    }
    
    public function __unset( $key )
    {
        
    }
}