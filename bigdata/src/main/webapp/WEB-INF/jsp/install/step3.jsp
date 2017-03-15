<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c"%>
<%@ taglib prefix="s" uri="http://www.springframework.org/tags/form"%>
<!DOCTYPE html>
<html lang="en">
<head>
<title></title>
<meta charset="UTF-8" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta content="IE=edge,chrome=1" http-equiv="X-UA-Compatible">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="">
<meta name="author" content="">

<script type="text/javascript" src="<%=request.getContextPath()%>/js/jquery-1.7.2.js"></script>
<script type="text/javascript" src="<%=request.getContextPath()%>/js/jtopo-0.4.8-min.js"></script>
<script type="text/javascript">
	$(document).ready(function() {
		var hadoop = '${Hadoop}';
		var namenode = '${Hadoop_NameNode}';
		var datanode = '${Hadoop_DataNode}';
		var journalnode = '${Hadoop_JournalNode}';
		if(hadoop!=null && hadoop !=''){
			hadoop = eval("("+hadoop+")");
		}
		if(namenode!=null && namenode !=''){
			namenode = eval("("+namenode+")");
		}
		if(datanode!=null && datanode !=''){
			datanode = eval("("+datanode+")");
		}
		if(journalnode!=null && journalnode !=''){
			journalnode = eval("("+journalnode+")");
		}
		
		var canvas = document.getElementById('canvas');
        var stage = new JTopo.Stage(canvas);
        var scene = new JTopo.Scene();
        stage.add(scene);
        scene.background = '<%=request.getContextPath()%>/img/bigdata/bg.jpg';
        var cloudNode = new JTopo.Node('Hadoop');
        cloudNode.setSize(30, 26);
        cloudNode.setLocation(360,230);           
        cloudNode.layout = {type: 'tree', width:400, height: 300}
        //cloudNode.layout = {type: 'circle', radius: 150};
        cloudNode.setImage('<%=request.getContextPath()%>/img/bigdata/hadoop.png');
        scene.add(cloudNode);
        for(var i=0;i<hadoop.length;i++){
        	var node = new JTopo.Node(hadoop[i]);
            node.fillStyle = '200,255,0';
            node.radius = 150;
            node.setLocation(scene.width * Math.random(), scene.height * Math.random());
            node.layout = {type: 'tree', width:200, height: 150};
            //node.setImage('<%=request.getContextPath()%>/img/bigdata/namenode.png');
            //node.layout = {type: 'circle', radius: 80};
            scene.add(node);                                
            var link = new JTopo.Link(cloudNode, node);
            link.strokeColor = '255,255,0';
            scene.add(link);
            if(hadoop[i] == 'NameNode'){
            	 for(var j=0; j<namenode.length; j++){
                     var vmNode = new JTopo.Node('192.103.1.'+j);
                     vmNode.radius = 100;
                     vmNode.fillStyle = '255,255,0';
                     vmNode.setLocation(scene.width * Math.random(), scene.height * Math.random());
                     vmNode.setImage('<%=request.getContextPath()%>/img/bigdata/server.png');
                     scene.add(vmNode); 
                     var link = new JTopo.Link(node, vmNode);
                     link.strokeColor = '0,255,0';
                     scene.add(link);                            
                 }
            }else if(hadoop[i] == 'DataNode'){
            	for(var j=0; j<datanode.length; j++){
                    var vmNode = new JTopo.Node('192.102.1.'+j);
                    vmNode.radius = 100;
                    vmNode.fillStyle = '255,255,0';
                    vmNode.setLocation(scene.width * Math.random(), scene.height * Math.random());
                    vmNode.setImage('<%=request.getContextPath()%>/img/bigdata/server.png');
                    scene.add(vmNode);                                
                    var link = new JTopo.Link(node, vmNode);
                    link.strokeColor =  '165,42,42';
                    scene.add(link);                              
                }
            	
            }else if(hadoop[i] == 'JournalNode'){
            	for(var j=0; j<journalnode.length; j++){
                    var vmNode = new JTopo.Node('192.101.1.'+j);
                    vmNode.radius = 100;
                    vmNode.fillStyle = '255,255,0';
                    vmNode.setLocation(scene.width * Math.random(), scene.height * Math.random());
                    vmNode.setImage('<%=request.getContextPath()%>/img/bigdata/server.png');
                    scene.add(vmNode);                                
                    var link = new JTopo.Link(node, vmNode);
                    link.strokeColor =  '0,0,139';
                    scene.add(link);                              
                }
            }
        }
        JTopo.layout.layoutNode(scene, cloudNode, true);
        
        scene.addEventListener('mouseup', function(e){
            if(e.target && e.target.layout){
                JTopo.layout.layoutNode(scene, e.target, true);    
            }                
        });
	});
</script>
</head>
<body>
	<canvas width="2000px" height="1000px" id="canvas" style="border: 1px solid rgb(68, 68, 68); cursor: default; background-color: rgb(238, 238, 238);"></canvas>
</body>
</html>