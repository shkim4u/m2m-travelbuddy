<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="계좌 조회"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/BrowseAccount.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
