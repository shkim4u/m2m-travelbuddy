<%@ page import="java.util.*,java.io.*" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<html>
<head><title>파일 뷰어</title></head>
<body>
<h1>파일: secrets.txt</h1>
<pre>
<%
	// application.getRealPath() will not work in WebSphere and WebLogic for WAR deployment, it will be null
	BufferedReader reader = new BufferedReader(new FileReader(application.getRealPath("/secrets.txt")));
	try {
		String line = null;
		while(true) {
			line = reader.readLine();
			if ( null == line ) break;
			out.println(line);
		}
	} finally {
		if ( null != reader ) {
			try { reader.close(); } catch ( Exception e ) { }
		}
	}
%>
</pre>
</body>
</html>
