<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="관리자 메시지"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/Admin.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
