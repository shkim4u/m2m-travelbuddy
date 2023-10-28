<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<style type="text/css">
textarea { margin-top:.18em; background-color:#ffc; }
</style>

	<tr>
		<td align="center">
			<table cellpadding="0" cellspacing="0" class="detailBox" width="45%">
				<tr valign="top" align="center" class="titleRow">
					<td width="55%" align="left">&nbsp;&nbsp;프로필: 암호 변경</td>
					<td width="8%">&nbsp;</td>
                    <td width="8%">&nbsp;</td>
				</tr>

                        <s:form action="PerformChangePass" method="POST" theme="simple">
                            <tr valign="top">
                                <td class="dataCell alt" align="center">이전 암호:</td>
                                <td class="dataCell alt" align="right"><s:password name="old" size="20"/>&nbsp;</td>
                                <td class="dataCell alt" width="8%">&nbsp;</td>
                            </tr>
                            <tr valign="top">
                                 <td class="dataCell alt" align="center">신규 암호:</td>
                                 <td class="dataCell alt" align="right"><s:password name="new1" size="20"/>&nbsp;</td>
                                <td class="dataCell alt" width="8%">&nbsp;</td>
                             </tr>
                            <tr valign="top">
                                 <td class="dataCell alt" align="center">신규 암호 확인:</td>
                                 <td class="dataCell alt" align="right"><s:password name="new2" size="20"/>&nbsp;</td>
                                <td class="dataCell alt" width="8%">&nbsp;</td>
                             </tr>
                            <tr valign="top">
                            <tr>
                                <td colspan="3" class="dataCell alt" align="center">

                                   <s:submit value="Submit"/>
                                </td>
                            </tr>
                        </s:form>
		</table>
			<br />
		</td>
	</tr>
