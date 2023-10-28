<%@ include file="../pages/common/moduleInclude.jsp" %>
<%--<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>--%>
<%@ page language="java" pageEncoding="UTF-8" %>

<%
response.setHeader("Cache-Control","no-store"); //HTTP 1.1
response.setHeader("Pragma","no-cache"); //HTTP 1.0
response.setDateHeader ("Expires", 0); //prevents caching at the proxy server
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>리치웰스 인터내셔널 홈페이지</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<%--<meta http-equiv="Content-Type" content="text/html" />--%>
<META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE"/>
<script language="javascript">AC_FL_RunContent = 0;</script>
<script src="<s:url value="/js/AC_RunActiveContent.js"/>" language="javascript"></script>
<link rel="stylesheet" type="text/css" href="<s:url value="/css/rwi-2.css"/>" />
<link rel="shortcut icon" href="<s:url value="/img/favicon.ico"/>" />
</head>
<body>
<br />
<table cellpadding="0" cellspacing="0" id="content" border="0" align="center">
	<tr valign="mtop">
		<td colspan="2">
			<table cellpadding="0" cellspacing="0" border="0">
				<tr valign="middle">
					<td id="utilities" align="right"><a href="<s:url action="../FindLocations"/>">위치 검색</a> | <a >담당자 문의</a> | <a >사이트 맵</a>&nbsp;</td>
					<td id="search" align="right" ><form id="search" action="" method="get" >
							<input type="text" size="28" maxlength="75" name="query" id="searchbox" title="Search" height="24" align="absmiddle" />
							<input type="image" src="<s:url value="/img/btn_search_white.gif" includeParams="none"/>" alt="Search" name="searchBtn" id="searchbtn"  align="absmiddle" disabled/>
						</form></td>
				</tr>
			</table>
		</td>
	</tr>
	<tr valign="top">
		<td align="left"><img id="header" src="<s:url value="/img/header.gif" includeParams="none"/>" /></td>
	</tr>
	<tr valign="top" id="menubar">
		<td colspan="2">
			<table cellpadding="0" cellspacing="0" border="0" align="right">
				<tr valign="top">
					<td><a  title="개인 뱅킹 서비스">개인</a></td>
					<td><a  title="중소 기업. 연간 매출 최대 200억원 이하 중소 기업 대상 서비스">중소 기업</a></td>
					<td><a  title="커머셜. 연간 매출 200억원 초과 기업 대상 서비스">커머셜</a></td>
					<td><a  title="RWI 정보">RWI에 대하여</a></td>
				</tr>
			</table>
		</td>
	</tr>
	<tr valign="top">
		<td>
			<table cellpadding="0" cellspacing="0" border="0">
				<tr valign="top">
					<td>
						<table cellpadding="0" cellspacing="0" border="0" align="left" id="left">
							<tr valign="top">
								<td>
									<table cellpadding="0" cellspacing="0" border="0" id="onlinebanking">
									<tr valign="top">
										<td id="signon_title">리치웰스 온라인 뱅킹</td>
									</tr>
									<tr valign="top">
<%--
                                        <td id="accounts" width="100%" height="30"><form action="" method="post" name="signon" >
												<label for="accounts">Go to</label>
												:&nbsp;
												<select id="goto" name="accounts" id="accounts" style="margin-left:4px">
												<option value="AccountSummary" selected="selected">Account Summary</option>
												<option value="Transfer">Transfer</option>
												<option value="Messages">Messages &amp; Alerts</option>
                                                </select>
											</form>
										</td>
--%>
                                    </tr>
                                    <tr>
                                        <td>
                                            <c:choose>
                                                <c:when test="${param.errorMsg != null}" >
                                                    <font color="red">${param.errorMsg}</font>
                                                </c:when>
                                            </c:choose>
                                        </td>
                                    </tr>
                                    <tr valign="top">
                                        <td id="userid">

                                            <s:form action="j_security_check" method="GET" theme="simple">
                                                <strong><s:label value="사용자ID:" for="j_username" /></strong><br />
                                                <s:textfield name="j_username" id="j_username" maxLength="50" cssStyle="width:140px"/><br />
                                                <strong><s:label value="암호:" for="j_username" /></strong><br />
                                                <s:password name="j_password" id="j_password" maxLength="50" cssStyle="width:140px"/>
                                                <input type="image" align="absmiddle" alt="Go" src="<s:url value="/img/btn_go_white.gif" includeParams="none"/>" value="Submit"/>
                                                <%-- <s:submit align="absmiddle" type="image" src="/riches/img/btn_go_white.gif"/> align doesn't work--%>
                                            </s:form>

											<p id="signup">회원 등록을 하고 싶으신가요?<br/>
												<a href="<s:url action="Register"/>?template=/pages/acquired/default.jsp">회원 등록</a> 혹은 <a >둘러보기</a></p>
                                        </td>
									</tr>
									<tr valign="top">
										<td>
											<img align="middle" src="<s:url value="/img/horizontall.gif" includeParams="none"/>" />
										</td>
									</tr>
									<tr valign="top">
										<td>
											<h2>회원 서비스</h2>
											<p id="services"> <a >세금 관련 문의</a><br />
												<a >모바일 뱅킹</a><br />
												<a >온라인 이체</a><br />
												<a >&gt;&gt;&nbsp;그외 서비스</a></p>
										</td>
									</tr>
									<tr valign="top">
										<td>
											<img align="middle" src="<s:url value="/img/horizontall.gif" includeParams="none"/>" />
										</td>
									</tr>
									<tr valign="top">
										<td>
											<h2>ATM 위치 검색</h2>
											<form id="locator" action="<s:url action="../ShowLocations"/>" >
												<input type="text" size="28" maxlength="70" id="zip" name="zip" value="우편번호 혹은 시/군/구 입력" title="ATM 위치 검색" style="float:left;width:147px" onclick="this.select();this.style.color='#000';" onfocus="this.select();this.style.color='#000';"/>
												<input type="image" src="<s:url value="/img/btn_go_white.gif" includeParams="none"/>" id="locationGo" name="locationGo" alt="찾기" style="clear:right;margin:1px 0 0 5px;padding:0"/>
											</form>
										</td>
									</tr>
									<tr valign="top">
										<td>
											<img align="middle" src="<s:url value="/img/horizontall.gif" includeParams="none"/>" />
										</td>
									</tr>
									<tr valign="top">
										<td>
											<h2>사기 방지/온라인 보안</h2>
											<p id="services"> <a >의심스러운 이메일 신고</a><br />
												<a >사기 및 개인 정보 탈취</a><br />
												<a >RWI 보안 플러스&trade;</a><br />
												<a >온라인 보안 보증</a></p>
										</td>
									</tr>
							</table>
								</td>
							</tr>
							<tr valign="top">
								<td>
								<table cellpadding="0" cellspacing="0" border="0" id="bg_image">
									<tr valign="top">
										<td>
											<img width="248" src="<s:url value="/img/accounts_bg_home.gif" includeParams="none"/>" />
										</td>
									</tr>
								</table>
							</td>
							</tr>
							<tr valign="top">
								<td><br /></td>
							</tr>
						</table>
					</td>
					<td>
						<table cellpadding="0" cellspacing="0" border="0" align="right" id="right">
							<tr valign="top">
								<td colspan="3" align="center">
									<img width="300" src="<s:url value = "/img/online-banking.gif" includeParams="none"/>" />
<%--									<script language="javascript">--%>
<%--										if (AC_FL_RunContent == 0) {--%>
<%--											alert("This page requires AC_RunActiveContent.js.");--%>
<%--										} else {--%>
<%--											AC_FL_RunContent(--%>
<%--												'codebase', 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0',--%>
<%--												'width', '731',--%>
<%--												'height', '194',--%>
<%--												'src', 'rwi-1',--%>
<%--												'quality', 'high',--%>
<%--												'pluginspage', 'http://www.macromedia.com/go/getflashplayer',--%>
<%--												'align', 'middle',--%>
<%--												'play', 'true',--%>
<%--												'loop', 'true',--%>
<%--												'scale', 'showall',--%>
<%--												'wmode', 'window',--%>
<%--												'devicefont', 'false',--%>
<%--												'id', 'rwi-1',--%>
<%--												'bgcolor', '#ffffff',--%>
<%--												'name', 'rwi-1',--%>
<%--												'menu', 'true',--%>
<%--												'allowFullScreen', 'false',--%>
<%--												'allowScriptAccess','sameDomain',--%>
<%--												'movie', '<s:url value="/rwi-1" includeParams="none"/>',--%>
<%--												'salign', ''--%>
<%--												); //end AC code--%>
<%--										}--%>
<%--									</script>--%>
<%--									<noscript>--%>
<%--										<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="731" height="194" id="rwi-1" align="middle">--%>
<%--										<param name="allowScriptAccess" value="sameDomain" />--%>
<%--										<param name="allowFullScreen" value="false" />--%>
<%--										<param name="movie" value="rwi-1.swf" /><param name="quality" value="high" /><param name="bgcolor" value="#ffffff" />	<embed src="<s:url value="/rwi-1.swf" includeParams="none"/>" quality="high" bgcolor="#ffffff" width="731" height="194" name="rwi-1" align="middle" allowScriptAccess="sameDomain" allowFullScreen="false" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />--%>
<%--										</object>--%>
<%--									</noscript>--%>
								</td>
							</tr>
							<tr valign="top" class="links">
								<!-- 1st row -->
								<td width="33%" ><h2 class="row1title">&nbsp;&nbsp;뱅킹</h2>
									<a >수표 처리</a><br />
									<a  title ="Start Saving Today">예금 및 저축</a><br />
									<a  title ="Click here for Rewards">신용 카드</a><br />
									<a  title ="Enroll for Free!">온라인 뱅킹</a><br />
									<a  title ="Get Started for Free">지불</a><br />
									<a  class="last" title="더 많은 계과 은행 계좌 관련 서비스"><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
								<td width="33%"><h2 class="row1title">&nbsp;&nbsp;대출</h2>
									<a  title ="Sign up to Get Rate Email Alerts">주택 담보 대출</a><br />
									<a  title ="Learn about Home Equity">주택 자본 대출</a><br />
									<a  title ="개인 대출 금리 및 지불">개인 대출</a><br />
									<a  title ="Automobile Loan Rates and Payments">자동차 오토론</a><br />
									<a  title ="Get a Student Loan">학자금 대출</a><br />
									<a  class="last" title="More loans and credit options" ><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
								<td width="33%"><h2 class="row1title" class="inv">&nbsp;&nbsp;투자</h2>
									<a  title ="Open an Account Today">뮤추얼 펀드</a><br />
									<a  title ="Find Out About Commission-Free Trades">거래 중개</a><br />
									<a  title ="Start Saving for Your Future Now!">퇴직 연금 관리</a><br />
									<a  title ="Protect Your Family">보험</a><br />
									<a  title ="Your own Private Bank">프라이빗 뱅킹</a><br />
									<a  class="last" title="More investing and insurance"><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
							</tr>
							<tr valign="top" class="links">
								<!-- 2st row -->
								<td width="33%"><h2 class="row2title">&nbsp;&nbsp;계좌 개설</h2>
									<a  title ="Open a Checking Account Today">수표 거래 계좌</a><br />
									<a  title ="Open a Saving Account Today">저축 계좌</a><br />
									<a  title ="Apply For a Credit Card">신용 카드</a><br />
									<a  title ="Open a CD Account Today">요구불 계좌</a><br />
									<a  title ="Open Money Market Account">자본 시장 계좌</a><br />
									<a  class="last" title="Other Types of Accounts"><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
								<td width="34%"><h2 class="row2title">&nbsp;&nbsp;오늘 금리 확인</h2>
									<a  title ="">담보 대출</a><br />
									<a  title ="">주택 대출</a><br />
									<a  title ="">신용 카드</a><br />
									<a  title ="">개인 신용 대출</a><br />
									<a  title ="">자동차 오토론</a><br />
									<a  class="last" title="Get Other Rates" ><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
								<td width="33%"><h2 class="row2title" class="inv">&nbsp;&nbsp;기타 업무</h2>
									<a  title ="">퇴직 센터</a><br />
									<a  title ="">주택 마련</a><br />
									<a  title ="">학자금 마련</a><br />
									<a  title ="">부채 조정</a><br />
									<a  title ="">투자 수단</a><br />
									<a  class="last" title=""><strong>&gt;&gt;</strong>&nbsp;그 외 업무</a>
								</td>
							</tr>
							<tr valign="top" class="links">
								<!-- 3rd row -->
								<td><br />
									<img src="<s:url value="/img/small-ad3.gif" includeParams="none"/>" />
								</td>
								<td><br />
									<img style="margin-left:.25em;" src="<s:url value="/img/small-ad1.gif" includeParams="none"/>" />
								</td>
								<td><br />
									<img src="<s:url value="/img/small-ad2.gif" includeParams="none"/>" />
								</td>
							</tr>
							<tr valign="top" class="footer">
								<td colspan="3">
								<br />
									<p id="footerNav"><a href="<s:url value="../pages/About.jsp"/>">RWI에 대하여</a> | <a href="<s:url action="../Careers"/>">커리어</a> | <a href="<s:url action="../Security"/>?privacy_statement=http://www.hp.com/country/us/en/privacy.html">개인 정보, 보안 및 법적 보호</a> | <a >이메일 사기 신고</a> | <a >다양성 및 접근성</a>  <br /><a >거래에 관한 중요 공지</a> | <a >온라인 접근성 선언 (3/06/2008) </a> | <a >사이트 맵</a></p>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
			<table cellpadding="0" cellspacing="0" border="0" align="center">
				<tr valign="top">
					<td>
						<p id="copy"><img src="<s:url value="/img/al_ehl_house_gen.gif" includeParams="none"/>" alt="" width="14" height="10" style="padding:0 5px 0 15px" /><strong style="color:#000">차별없는 주택 금융</strong><br />RWI - 금융거래위원회 회원 &copy; 2018 RWI. All rights reserved. </p>
					</td>
				</tr>
			</table>
			<br />
		</td>
	</tr>
</table>
<script>
	document.getElementById("j_username").focus();
</script>
</body>
</html>
