<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<% 
	String rtData = request.getAttribute("rtData")==null?"{}":(String)request.getAttribute("rtData");
	int rtState = request.getAttribute("rtState")==null?1:(Integer)request.getAttribute("rtState");
	String rtMsg = request.getAttribute("rtMsg")==null?"":(String)request.getAttribute("rtMsg");
	rtMsg = rtMsg.replace("\"","\\\"").replace("\r\n","\\r\\n");
	rtData = rtData.replace("\r","\\r").replace("\n","\\n");
%>
<%out.clear(); %>
{"rtState":"<%=rtState %>","rtData":<%=rtData%>,"rtMsg":"<%=rtMsg %>"}