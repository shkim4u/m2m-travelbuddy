<% response.setStatus(200); %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head><title>오류</title></head>
<body>
<% java.util.Date d = new java.util.Date(); %>
<% java.util.Random r = new java.util.Random(); %>
<h1>
    오류가 발생했습니다. 시스템 관리자에게 문의하세요. 오류 코드: <%= r.nextInt() + "" %> . 페이지: ${pageContext.request.requestURI}.
</h1>
Date stamp: <%= d.toString() %>.
</body>
</html>

