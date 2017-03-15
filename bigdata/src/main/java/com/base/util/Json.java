package com.base.util;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Set;
import java.util.Stack;
import java.util.Map.Entry;

import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

public class Json {
	public final String quote = "\"";
	
	private SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	
	private Map filter = new HashMap();
	
	private Map<Class,String[]> filter4Class = new HashMap<Class,String[]>();
	
	private Map<String,JsonParsing> parsing = new HashMap<String,JsonParsing>();
	
	public void setDateFormat(SimpleDateFormat sdf){
		this.sdf = sdf;
	}
	
	/**
	 * 字段名称过滤器，例如将所有seqId过滤成为id，从而拼出json
	 * @param o
	 * @param t
	 */
	public void addFieldFilter(String o,String t){
		filter.put(o, t);
	}
	
	/**
	 * 字段名称过滤器，例如将指定类的seqId过滤成为id，从而拼出json
	 * addFieldFilter(Student.class,new String[]{"seqId","id"})
	 * @param clazz
	 * @param mapping
	 */
	public void addFieldFilter(Class clazz,String[] mapping){
		filter4Class.put(clazz, mapping);
	}
	
	public Json addParsingListener(String field,JsonParsing jsonParsing){
		parsing.put(field, jsonParsing);
		return this;
	}
	
	/**
	 * 从JSON字符串转换成json数组
	 * @param json
	 * @param clazz
	 * @return
	 */
	public Object toArray(String json,Class clazz){
		JSONArray jsonArray = JSONArray.fromObject(json);
		return JSONArray.toArray(jsonArray, clazz);
	}
	
	/**
	 * 从JSON字符串转换成json对象
	 * @param json
	 * @param clazz
	 * @return
	 */
	public Object toObject(String json,Class clazz){
		JSONObject jsonObject = JSONObject.fromObject(json);
		return JSONObject.toBean(jsonObject, clazz);
	}
	
	/**
	 * 将List对象转换为Json数组
	 * @param list
	 * @return
	 */
	public String toJson(List<?> list){
		StringBuffer tmp = new StringBuffer();
		tmp.append("[");
		boolean hasExist = false;
		for(Object o:list){
			hasExist = true;
			if(o instanceof Integer
					|| o instanceof Long
					|| o instanceof Short
					|| o instanceof Double
					|| o instanceof Float
					|| o instanceof Byte){
				
				tmp.append(o+",");
				
			}else if(o instanceof String || o instanceof Character){
				tmp.append(quote+o+quote+",");
			}else{
				tmp.append(toJson(o)+",");
			}
		}
		if(hasExist){
			tmp.deleteCharAt(tmp.length()-1);
		}
		tmp.append("]");
		return tmp.toString();
	}
	
	/**
	 * 将Map、实体类对象     转换为Json数组
	 * @param list
	 * @return
	 */
	public String toJson(Object obj){
		StringBuffer tmp = new StringBuffer();
		tmp.append("{");
		Class<?> clazz = obj.getClass();
		Field fields[] = null;
		Method methods[] = null;
		String jsons = "";
		if(clazz == HashMap.class || clazz == HashSet.class){
			jsons = toKeyValues((Map)obj);
		}else{
			fields = clazz.getDeclaredFields();
			methods = clazz.getDeclaredMethods();
			jsons = toKeyValues(fields,methods,obj,clazz);
		}
		tmp.append(jsons);
		tmp.append("}");
		return tmp.toString();
	}
	
	
	private String toKeyValues(Field fields[],Method methods[],Object o,Class clazz){
		StringBuffer tmp = new StringBuffer();
		boolean hasExist = false;
		for(Field field:fields){
			for(Method method:methods){
				if(method.getName().toLowerCase().indexOf(field.getName().toLowerCase())!=-1
						&& method.getReturnType()!=void.class){
					tmp.append(toKeyValue(field,method,o,clazz)+",");
					hasExist = true;
					break;
				}
			}
		}
		if(hasExist){
			tmp.deleteCharAt(tmp.length()-1);
		}
		return tmp.toString();
	}
	
	private String toKeyValues(Map params){
		Set<Entry> entry = params.entrySet();
		Iterator it = entry.iterator();
		StringBuffer tmp = new StringBuffer();
		String key = null;
		Object value = null;
		Entry en = null;
		boolean hasExist = false;
		while(it.hasNext()){
			hasExist = true;
			en = (Entry) it.next();
			key = (String) en.getKey();
			value = (Object) en.getValue();
			tmp.append(toKeyValue(key,value,null)+",");
		}
		if(hasExist){
			tmp.deleteCharAt(tmp.length()-1);
		}
		return tmp.toString();
	}
	
	private String toKeyValue(String key,Object value,Class clazz){
		String tmp = "";
		JsonParsing jsonParsing = parsing.get(key);
		value = (jsonParsing==null?value:jsonParsing.parse(value));
		
		String [] mapping = filter4Class.get(clazz);
		if(mapping!=null && key.equals(mapping[0])){
			key = mapping[1];
		}else{
			key = filter.get(key)==null?key:(String)filter.get(key);
		}
		
		key = quote+key+quote;
		if(value instanceof ArrayList){//if ArrayList
			tmp = key+":"+toJson((List<?>)value);
		}else if(value instanceof Integer
				|| value instanceof Long
				|| value instanceof Short
				|| value instanceof Double
				|| value instanceof Float
				|| value instanceof Byte){
			
			tmp = key+":"+value;
			
		}else if(value instanceof String
				|| value instanceof Character){
			value = ((String)value).replace("\\", "\\\\").replace("\"", "\\\"");
			
			if(value instanceof String){
				tmp = key+":"+quote+value+quote;
			}else{
				tmp = key+":"+quote+value+quote;
			}
			
		}else if(value instanceof java.util.Date){
			
			tmp = key+":"+quote+(sdf!=null?sdf.format(value):((java.util.Date)value).getTime())+quote;
			
		}else if(value instanceof java.sql.Date){
			
			tmp = key+":"+quote+value+quote;
			
		}else if(value==null){
			
			tmp = key+":"+null;
			
		}else{
			tmp = key+":"+toJson(value);
		}
		return tmp;
	}
	
	private String toKeyValue(Field field,Method method,Object o,Class clazz){
		String key = field.getName();
		Object value = null;
		String tmp = "";
		try {
			value = method.invoke(o, null);
			tmp = toKeyValue(key, value,clazz);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return tmp;
	}
	
	public String maptojson(String key,String json){
		Map<String,Object> map = new HashMap<String, Object>();
		map.put(key,json);
		String value = toJson(map);
		return value;
	}
	
	public static void main(String[] args) {
		Json json = new Json();
		List<String> list = new ArrayList<String>();
		list.add("192.168.0.1");
		list.add("192.168.0.2");
		list.add("192.168.0.3");
		String str = json.toJson(list);
		System.out.println(str);
	}
}
