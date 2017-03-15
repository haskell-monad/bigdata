/*
Navicat MySQL Data Transfer

Source Server         : 192.168.98.120
Source Server Version : 50173
Source Host           : 192.168.98.120:3306
Source Database       : bigdata

Target Server Type    : MYSQL
Target Server Version : 50173
File Encoding         : 65001

Date: 2015-10-19 17:18:59
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `bigdata_node_type`
-- ----------------------------
DROP TABLE IF EXISTS `bigdata_node_type`;
CREATE TABLE `bigdata_node_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of bigdata_node_type
-- ----------------------------
INSERT INTO `bigdata_node_type` VALUES ('1', '0', 'Hadoop');
INSERT INTO `bigdata_node_type` VALUES ('2', '0', 'HBase');
INSERT INTO `bigdata_node_type` VALUES ('3', '0', 'Hive');
INSERT INTO `bigdata_node_type` VALUES ('4', '0', 'Zookeeper');
INSERT INTO `bigdata_node_type` VALUES ('5', '0', 'Pig');
INSERT INTO `bigdata_node_type` VALUES ('6', '1', 'NameNode');
INSERT INTO `bigdata_node_type` VALUES ('7', '1', 'DataNode');
INSERT INTO `bigdata_node_type` VALUES ('8', '1', 'JournalNode');
INSERT INTO `bigdata_node_type` VALUES ('9', '1', 'ResourceManager');
INSERT INTO `bigdata_node_type` VALUES ('10', '1', 'NodeManager');
INSERT INTO `bigdata_node_type` VALUES ('11', '1', 'HistoryServer');

-- ----------------------------
-- Table structure for `bigdata_ssh_info`
-- ----------------------------
DROP TABLE IF EXISTS `bigdata_ssh_info`;
CREATE TABLE `bigdata_ssh_info` (
  `id` int(255) NOT NULL AUTO_INCREMENT,
  `ip` varchar(255) NOT NULL COMMENT 'ssh ip',
  `port` varchar(255) NOT NULL COMMENT 'ssh 端口号（默认22）',
  `user` varchar(255) NOT NULL COMMENT 'ssh 用户（默认root）',
  `passwd` varchar(255) NOT NULL COMMENT 'ssh 密码',
  `rsa_key` int(11) DEFAULT NULL COMMENT '是否配置ssh key（0：未设置，1：已设置，2：设置失败，默认0）',
  `install_status` int(11) DEFAULT NULL COMMENT '安装状态（0：未初始化，1：正在安装，2：安装失败， 5：完成，默认0）',
  `create_time` datetime DEFAULT NULL COMMENT '节点创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '节点更新时间',
  `node_type` varchar(255) NOT NULL COMMENT '应用节点类型',
  `node_name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of bigdata_ssh_info
-- ----------------------------
INSERT INTO `bigdata_ssh_info` VALUES ('1', '192.168.98.[120,57,201,175]', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:26:07', null, 'Hadoop', 'NameNode');
INSERT INTO `bigdata_ssh_info` VALUES ('3', '192.168.98.[57,201,175]', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:27:46', null, 'Hadoop', 'JournalNode');
INSERT INTO `bigdata_ssh_info` VALUES ('4', '192.168.98.[57,201,231,124,152] 192.168.99.92', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:28:23', null, 'Hadoop', 'DataNode');
INSERT INTO `bigdata_ssh_info` VALUES ('5', '192.168.98.120', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:28:58', null, 'Hadoop', 'ResourceManager');
INSERT INTO `bigdata_ssh_info` VALUES ('6', '192.168.98.[57,231,124,152]', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:29:39', null, 'Hadoop', 'NodeManager');
INSERT INTO `bigdata_ssh_info` VALUES ('7', '192.168.99.92', '22', 'root', 'ikang', '0', '0', '2015-04-19 08:30:27', null, 'Hadoop', 'HistoryServer');
INSERT INTO `bigdata_ssh_info` VALUES ('8', '192.168.98.[231,124,152]', '22', 'root', 'ikang', '0', '0', '2015-10-14 13:01:35', null, 'Zookeeper', 'Zookeeper');
INSERT INTO `bigdata_ssh_info` VALUES ('9', '', '22', 'root', 'ikang', '0', '0', '2015-10-14 13:01:38', null, 'Hive', 'Hive');
