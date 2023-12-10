<!-- Page is coming from pebble,  web/WEB-INF/jsp/error.jsp -->

<%@ page isErrorPage="true" %>

<div class="contentItem">

  <h1>문서를 찾는 중 오류가 발생했습니다.</h1>
  <h2>&nbsp;</h2>

  <div class="contentItemBody">
    <fmt:message key="error.error" />

    <br /><br />
    <a href="javascript:toggleVisibility('stacktrace')"><fmt:message key="common.readMore"/></a>
    <br /><br />

    <textarea id="stacktrace" rows="10" cols="60" readonly="true">
${stackTrace}
요청 URL : ${pageContext.request.requestURL}
요청 URI : ${pageContext.request.requestURI}
쿼리 문자열 : ${pageContext.request.queryString}
외부 URI : ${externalUri}
내부 URI : ${internalUri}
파라미터 : <c:forEach var="entry" items="${paramValues}">
<c:forEach var="value" items="${entry.value}">${entry.key} = ${value}
</c:forEach></c:forEach>
</textarea>
  </div>

</div>
