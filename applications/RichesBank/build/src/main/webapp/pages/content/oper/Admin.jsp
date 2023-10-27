<%@ include file="../../common/moduleInclude.jsp" %>
	<tr>
		<td>
			<table cellpadding="0" cellspacing="0" class="messageBox" width="60%" align="center">
                <c:choose>
                    <c:when test="${auth}">
                <s:form action="SendMessage" method="POST" theme="simple">
                    <tr valign="top" class="titleRow">
                        <td  align="left">&nbsp;&nbsp;메시지 전송 대상:</td>
                    </tr>
                    <tr valign="top" class="subtitle">
                        <td align="left">
                            <table border=0 cellpadding="0" cellspacing="0"><tr><td style="border:0px" width="50px"><strong>To:</strong><td style="border:0px"><s:select list="addresses" label="To" name="to"/></td></tr></table>
                        </td>
                    </tr>
                    <tr class="subtitle">
                        <td colspan="2" align="left">
                            <table cellpadding="0" cellspacing="0"><tr ><td style="border:0px" width="50px"><strong>Severity:</strong></td><td style="border:0px"><s:textfield label="Severity" name="severity" size="10"/></td></tr></table>
                        </td>
                    </tr>
                    <tr class="subtitle">
                        <td colspan="2" align="left">
                            <table cellpadding="0" cellspacing="0"><tr ><td style="border:0px" width="50px"><strong>Subject:</strong></td><td style="border:0px"><s:textfield label="Subject" name="subject" size="50"/></td></tr></table>
                        </td>
                    </tr>
                    <tr valign="top">
                        <td>
                            <table cellspacing="0" width="100%" align="center">
                                    <tr class="dataCell">
                                        <td colspan="2" align="left"><s:textarea label="Body" name="body" cols="114" rows="12"/></td>
                                    </tr>
                                    <tr class="dataCell" align="left">
                                        <td colspan="2">&nbsp;<input type="image" src="<s:url value="/img/btnSend.gif" includeParams="none"/>" alt="Send"  align="absmiddle" /></td>
                                    </tr>
                            </table>
                        </td>
                    </tr>
                </s:form>
                    </c:when>
                    <c:otherwise>
                        <tr valign="top" align="center" class="titleRow">
                            <td width="35%" align="left">&nbsp;&nbsp;Access Denied:</td>
                        </tr>
                         <tr>
                        <td class="dataCell" align="center" width="100%">이 페이지를 볼 수 있는 권한이 없습니다.</td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </table>
            <br>
        </td>
	</tr>
