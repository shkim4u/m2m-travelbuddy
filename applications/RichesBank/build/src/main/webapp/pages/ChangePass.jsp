<%@ include file="common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="암호 변경"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/ChangePass.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
