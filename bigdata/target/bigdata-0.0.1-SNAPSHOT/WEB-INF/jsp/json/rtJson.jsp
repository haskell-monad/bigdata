<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
String rtData = request.getAttribute("rtData")==null?"{}":(String)request.getAttribute("rtData");
%>
<%out.clear(); %>
<%=rtData.replace("\r","\\r").replace("\n","\\n")%>