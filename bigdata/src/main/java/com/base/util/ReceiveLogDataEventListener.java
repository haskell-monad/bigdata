package com.base.util;

import java.util.EventListener;
import java.util.List;

/**
 * 接收数据 事件监听接听接口
 * @author hadoop
 */
public interface ReceiveLogDataEventListener extends EventListener{
	
	/**
	 * 处理数据
	 * @param list 传输过来的数据
	 */
	public void processLogData(List<String> list);
}
