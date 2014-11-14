<?php
class getdeviceosversionmodel extends CI_Model
{
	function __construct()
	{
		parent::__construct ();
		$this->load->model ( 'api/common', 'common' );
		$this->load->database ();
	}

	function getdeviceosversion($sessionkey, $productid, $fromtime, $totime,$topnum)
	{
		try {
			$userid = $this->common->getuseridbysessionkey ( $sessionkey );
			if ($userid)
			{
				$verify = $this->common->verifyproductbyproductid ( $userid, $productid );
				if ($verify)
				{
					$basic = $this->getdeviceosversiondata($productid, $fromtime, $totime,$topnum);
					if ($basic)
					{
						$productinfo = array (
								'flag' => 2,
								'queryResult' => $basic
						);
					}
					else
					{
						$productinfo = array (
								'flag' => - 4,
								'msg' => 'No data information'
						);
					}
				}
				else
				{
					$productinfo = array (
							'flag' => - 6,
							'msg' => 'Do not have permission'
					);
				}
				return $productinfo;
			}
			else
			{
				$productinfo = array (
						'flag' => - 2,
						'msg' => 'Sessionkey is invalide '
				);
				return $productinfo;
			}
		}
		catch ( Exception $ex )
		{
			$productinfo = array (
					'flag' => - 3,
					'msg' => 'DB Error'
			);
			return $productinfo;
		}
	}

	function getdeviceosversiondata($productid, $fromtime, $totime,$topnum)
	{
		$content=array();
		$active =   $this->getactiveosversion($productid, $fromtime, $totime,$topnum);
		$new    =   $this->getnewosversion($productid, $fromtime, $totime,$topnum);
		$content['newusers']=array();
		$content['activeusers']=array();
		if($active)
		{
			for($i=0;$i<count($active);$i++)
			{
				$obj=array(
						'id'=>$i+1,
						'osversion'=>$active[$i]['deviceos_name'],
						'num'=>$active[$i]['count']
						);
				array_push($content['activeusers'], $obj);
			}
		}
		if($new)
		{
			for($i=0;$i<count($new);$i++)
			{
				$obj=array(
						'id'=>$i+1,
						'osversion'=>$new[$i]['deviceos_name'],
						'num'=>$new[$i]['count']
				);
				array_push($content['newusers'], $obj);
			}
		}
		if(count($content)>0)
		{
			return  $content;
		}
		else
		{
			return false;
		}
		
				
				
				
	}

	function getactiveosversion($productid, $fromtime, $totime,$topnum)
	{
		$dwdb = $this->load->database('dw',TRUE);
		if($topnum!=null)
		{
			$sql = "select   o.deviceos_name,
			count(distinct f.deviceidentifier) count
			from ".$dwdb->dbprefix('fact_clientdata')." f,
			".$dwdb->dbprefix('dim_date')." d,
			".$dwdb->dbprefix('dim_product')." p,
			".$dwdb->dbprefix('dim_deviceos')." o
			where  f.date_sk = d.date_sk and
			f.product_sk = p.product_sk and
			f.deviceos_sk = o.deviceos_sk
			and d.datevalue between '$fromtime' and '$totime'
			and p.product_id = '$productid' and
			p.product_active=1 and p.channel_active=1
			and p.version_active=1
			group by o.deviceos_name
			order by count desc limit 0,$topnum;";
		}
		else
		{
			$sql = "select   o.deviceos_name,
			count(distinct f.deviceidentifier) count
			from ".$dwdb->dbprefix('fact_clientdata')." f,
			".$dwdb->dbprefix('dim_date')." d,
			".$dwdb->dbprefix('dim_product')." p,
			".$dwdb->dbprefix('dim_deviceos')." o
			where  f.date_sk = d.date_sk and
			f.product_sk = p.product_sk and
			f.deviceos_sk = o.deviceos_sk
			and d.datevalue between '$fromtime' and '$totime'
			and p.product_id = '$productid' and
			p.product_active=1 and p.channel_active=1
			and p.version_active=1
			group by o.deviceos_name
			order by count desc ;";
		}			
		$query = $dwdb->query($sql);
		if ($query != null && $query->num_rows () > 0)
		{
			$query = $query->result_array ();
			return $query;
		}
		else
		{
			return false;
		}
	}
	
	function getnewosversion($productid, $fromtime, $totime,$topnum)
	{
		$dwdb = $this->load->database('dw',TRUE);
		if($topnum!=null)
		{
			$sql = "select o.deviceos_name,
			count(distinct f.deviceidentifier) count
			from ".$dwdb->dbprefix('fact_clientdata')." f,"
			.$dwdb->dbprefix('dim_date')." d,"
			.$dwdb->dbprefix('dim_product')." p,"
			.$dwdb->dbprefix('dim_deviceos')." o
			where f.date_sk = d.date_sk
			and f.product_sk = p.product_sk
			and f.deviceos_sk = o.deviceos_sk
			and d.datevalue between '$fromtime' and '$totime'
			and p.product_id = '$productid'
			and p.product_active=1 and p.channel_active=1
			and p.version_active=1 and f.isnew=1
			group by o.deviceos_name
			order by count desc limit 0,$topnum;";
		}
		else
		{
			$sql = "select o.deviceos_name,
			count(distinct f.deviceidentifier) count
			from ".$dwdb->dbprefix('fact_clientdata')." f,"
			.$dwdb->dbprefix('dim_date')." d,"
			.$dwdb->dbprefix('dim_product')." p,"
			.$dwdb->dbprefix('dim_deviceos')." o
			where f.date_sk = d.date_sk
			and f.product_sk = p.product_sk
			and f.deviceos_sk = o.deviceos_sk
			and d.datevalue between '$fromtime' and '$totime'
			and p.product_id = '$productid'
			and p.product_active=1 and p.channel_active=1
			and p.version_active=1 and f.isnew=1
			group by o.deviceos_name
			order by count desc ;";
		}
		
		$query = $dwdb->query($sql);
		if ($query != null && $query->num_rows () > 0)
		{
			$query = $query->result_array ();
			return $query;
		}
		else
		{
			return false;
		}
	}

	
	
}