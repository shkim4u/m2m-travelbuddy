<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="계좌 삭제"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/DeleteAccount.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
