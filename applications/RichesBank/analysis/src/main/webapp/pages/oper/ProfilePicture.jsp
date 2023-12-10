<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<tiles:insertTemplate template="/pages/tiles/header.jsp">
    <tiles:putAttribute name="pageDesc" value="프로필 사진 변경"/>
</tiles:insertTemplate>
<tiles:insertTemplate template="/pages/content/oper/ProfilePicture.jsp"/>
<tiles:insertTemplate template="/pages/tiles/footer.jsp"/>
