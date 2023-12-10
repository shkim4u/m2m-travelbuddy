<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="대량 메시지: 뉴스레터"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/Newsletter.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
