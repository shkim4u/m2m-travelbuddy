<%@ include file="common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="메시지 상세 정보"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/ViewMessage.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
