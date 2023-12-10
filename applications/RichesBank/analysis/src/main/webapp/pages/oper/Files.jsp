<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="파일 페이지"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/Files.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
