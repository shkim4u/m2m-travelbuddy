<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.text.DateFormat" %>
<%@ page import="java.sql.Date" %>
<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<%
    NumberFormat numFormat = NumberFormat.getCurrencyInstance();
%>

    <tr>
		<td>
			<table cellpadding="0" cellspacing="0" class="detailBox" width="99%">
				<tr valign="top">
					<td>
						<table cellspacing="0"  width="100%" class="subtitle">
								<tr align="left">
                                    <td width="20%"><a href="">계좌 번호</a></td>
                                    <td width="15%"><a href="">날짜</a></td>
									<td width=""><a href="">설명</a></td>
									<td width="15%"><a href="">금액</a></td>
								</tr>

                                <%
                                    int size = ((java.util.List) request.getAttribute("transactions")).size();
                                    request.setAttribute("size", new Integer(size));
                                    DateFormat format = DateFormat.getDateInstance(DateFormat.SHORT);
                                %>
                                <c:choose>
                                    <c:when test="${size != 0}" >
                                        <c:forEach var="transaction" items="${transactions}">
                                            <tr class="alt">
                                                <td><c:out value="${transaction.acctno}"/></td>
                                                <c:set var="date" scope="request" value="${transaction.date}"/>
                                                <%
                                                    Date date = (Date) request.getAttribute("date");
                                                    request.setAttribute("date",format.format(date));
                                                %>
                                                <td>${date}</td>
                                                <td><c:out value="${transaction.description}"/></td>
                                                <c:set var="amount" scope="request" value="${transaction.amount}"/>
                                                <%
                                                    Double amount = (Double)request.getAttribute("amount");
                                                    request.setAttribute("amount", numFormat.format(amount.doubleValue()));
                                                %>
                                                <td align="right"><c:out value="${amount}"/></td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr class="alt">
                                            <td></td>
                                            <td>No transactions found.</td>
                                            <td></td>
                                            <td></td>
                                            <td></td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
<%--
								<tr>
									<td>2/29/2008</td>
									<td>&nbsp;</td>
									<td>Debit </td>
									<td><a href="">SERVICE CHARGE</a> </td>
									<td>&nbsp;</td>
									<td align="right">$20.00 </td>
									<td align="right">&nbsp;</td>
								</tr>
--%>
						</table>
					</td>
				</tr>
			</table>
            <br />
        </td>
	</tr>
