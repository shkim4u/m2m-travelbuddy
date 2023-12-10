<%@page language="java" pageEncoding="UTF-8" %>

<tr valign="top">
    <td colspan="2">
        <table cellpadding="0" cellspacing="0" border="0" width="100%" id="utilities">
            <tr valign="middle">
                <td align="right"><a href="/riches/">은행 홈페이지</a> | <a href="<s:url action="../FindLocations" includeParams="none"/>">위치 검색</a> | <a >담당자 문의</a>
                    | <a >도움말</a> | <a >개인 정보 보호 정책</a> | <a href="<s:url value="/login/Logout.action"/>">로그아웃</a>&nbsp;&nbsp;&nbsp;&nbsp;
                </td>
            </tr>
        </table>
    </td>
</tr>
<tr valign="top">
    <td align="left">
        <img id="logo" src="<s:url value="/img/rwi_50.gif" includeParams="none"/>"/>
    </td>
</tr>
<tr valign="top" id="menubar">
    <td colspan="2">
        <table cellpadding="0" cellspacing="0" border="0" align="right">
            <tr valign="top">
                <td><a href="<s:url value="/auth/AccountSummary.action" includeParams="none"/>" title="계좌 정보">계좌</a></td>
                <td><a href="<s:url value="/auth/Transfer.action" includeParams="none"/>" title="">이체</a></td>
                <td><a href="<s:url value="/auth/Check.action" includeParams="none"/>" title="">수표 발행</a></td>
                <td><a href="<s:url value="/auth/PayBill.action" includeParams="none"/>" title="">지불</a></td>
<%--                <td><a href="" title="">Make Payments</a></td> --%>
                <td><a href="<s:url value="/auth/Messages.action" includeParams="none"/>" title="">메시지</a></td>
                <td><a href="<s:url value="/auth/ChangePass.action" includeParams="none"/>" title="">암호 변경</a>&nbsp;&nbsp;&nbsp;&nbsp;</td>
                <td><a href="<s:url namespace="/auth/oper" action="ProfilePicture" includeParams="none"/>" title="">사진</a>&nbsp;&nbsp;&nbsp;&nbsp;</td>
            </tr>
            <tr valign="top">
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="Admin" includeParams="none"/>" title="">관리 메시지 발송</a>&nbsp;&nbsp;&nbsp;&nbsp;</td></c:if>
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="Newsletter" includeParams="none"/>" title="">대량 메일</a>&nbsp;&nbsp;&nbsp;&nbsp;</td></c:if>
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="AddAccount" includeParams="none"/>" title="">계좌 개설</a>&nbsp;&nbsp;&nbsp;</td></c:if>
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="DeleteAccount" includeParams="none"/>" title="">계좌 삭제</a>&nbsp;&nbsp;&nbsp;</td></c:if>
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="BrowseAccount" includeParams="none"/>" title="">계좌 조회</a>&nbsp;&nbsp;&nbsp;</td></c:if>
                <c:if test="${auth}"><td><a href="<s:url namespace="/auth/oper" action="Files" includeParams="none"/>" title="">파일</a>&nbsp;&nbsp;&nbsp;</td></c:if>
            </tr>
        </table>
    </td>
</tr>
