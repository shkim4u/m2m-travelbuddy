<%@ include file="common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="지불"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/PayBill.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
