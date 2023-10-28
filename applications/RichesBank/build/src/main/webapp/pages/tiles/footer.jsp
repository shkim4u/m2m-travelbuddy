<%@ include file="../common/moduleInclude.jsp" %>
<%@page language="java" pageEncoding="UTF-8" %>
<%
String name = (String) request.getAttribute("name");
String ssn = (String) request.getAttribute("ssn");
if (name != null && ssn != null) {
%>
	<tr>
		<td align="center">
			<span><%=name%> /SSN <%=ssn%></span>
		</td>
	</tr>
<%
}
%>
<tr>
    <td align="center">
        <div><a href=""><img src="<s:url value="/img/tiny-ad1.gif"/>" /></a></div>
    </td>
</tr>
<tr>
    <td>
        <br />
        <table cellpadding="0" cellspacing="0" border="0" align="center" id="footer">
            <tr valign="top">
                <td>
                    <p id="copy">RWI - 금융거래위원회 회원 &copy; 2018 RWI. All rights reserved.<img src="<s:url value="/img/al_ehl_house_gen.gif" includeParams="none"/>" alt="" width="14" height="10" style="padding:0 5px 0 15px" /><strong style="color:#000">차별업는 주택 금융</strong></p>
                </td>
            </tr>
        </table>
    </td>
</tr>
