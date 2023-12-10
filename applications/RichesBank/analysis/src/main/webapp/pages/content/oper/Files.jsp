<%@ include file="../../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.text.DateFormat" %>
<%@ page import="java.util.Date" %>

    <%
        String today = DateFormat.getDateInstance(DateFormat.SHORT).format(new Date());
        NumberFormat numFormat = NumberFormat.getCurrencyInstance();
    %>

	<tr>
		<td align="center">
			<table cellpadding="0" cellspacing="0" class="detailBox" width="90%">
				<tr valign="top" align="center" class="titleRow">
					<td width="35%" align="left">파일명</td>
					<td width="15%">파일 유형</td>
					<td width="30%">레벨</td>
				</tr>
            <tr valign="top">
               <td class="dataCell alt" align="center">디자인 문서</td>
               <td class="dataCell alt" align="center">워드</td>
               <td class="dataCell alt" align="center">미분류</td>
            </tr>
            <tr valign="top">
               <td class="dataCell alt" align="center"><a href="../../pages/FilesViewer.jsp">거래 비밀</a></td>
               <td class="dataCell alt" align="center">텍스트</td>
               <td class="dataCell alt" align="center">극비</td>
            </tr>

         </table>
			<br />
		</td>
	</tr>
