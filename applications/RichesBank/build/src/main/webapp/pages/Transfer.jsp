<%@ include file="common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="자금 이체"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/Transfer.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
