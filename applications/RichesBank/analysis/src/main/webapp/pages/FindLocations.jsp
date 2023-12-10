<%@ include file="common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/basicHeader.jsp">
    <tiles:putAttribute name="pageDesc" value="위치 검색"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/FindLocations.jsp"/>
<tiles:insertTemplate template="/pages/tiles/basicFooter.jsp"/>
