<%@ include file="../pages/common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>RWI - Riches Wealth International Home Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Type" content="text/html" />
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
                    <td id="utilities" align="right"><a >위치 검색</a> | <a >담당자 문의</a> | <a >사이트 맵</a>&nbsp;</td>
                    <td id="search" align="right" >
                        <form id="search" action="" method="get" >
							<input type="text" size="28" maxlength="75" name="query" id="searchbox" title="검색" height="24" align="absmiddle" />
							<input type="image" src="<s:url value="/img/btn_search_white.gif" includeParams="none"/>" alt="Search" name="searchBtn" id="searchbtn"  align="absmiddle" disabled/>
						</form>
                    </td>
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
                    <td valign="top">
                        <table cellpadding="0" cellspacing="0" border="0" align="left" id="left">
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
                        </table>
                    </td>
                    <td valign="top" id="userid" align="center">
                    	<br/>
			            <b>리치웰스 인터내셔널에 가입하세요!!</b>

                        <!-- When the user was redirected from one of the banks that were acquired, RWi states the name of the old bank
                        Example: http://yoursite.com/riches/login/Register.action?template=/pages/acquired/first_riches_invest.jsp
                        -->
                        <jsp:include page="<%= request.getParameter(\"template\") != null?(String)request.getParameter(\"template\"):\"/pages/acquired/default.jsp\" %>"/>

                        <table cellpadding="0" cellspacing="0" border="0" align="left" id="right" valign="top">
                        	<s:form action="PerformRegistration" method="POST" theme="simple">
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="성: " for="lastName" cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:textfield name="lastName" id="lastName" maxLength="50" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <br/><br/><br/>
                                    <td width="35%" valign="top" align="right">
                                        <s:label value="이름: " for="firstName" cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:textfield name="firstName" id="firstName" maxLength="50" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="이메일 주소: " for="email"  cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:textfield name="email" id="email" maxLength="70" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="주민등록번호: " for="ssn"  cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:textfield name="ssn" id="ssn" maxLength="70" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="center" colspan="2">
                                        <img align="middle" src="<s:url value="/img/horizontall.gif" includeParams="none"/>" />
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="사용자ID: " for="username"  cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:textfield name="username" id="username" maxLength="70" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="암호: " for="password"  cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:password name="password" id="password" maxLength="70" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="right">
                                        <s:label value="암호 확인: " for="confPassword"  cssStyle="font-weight:normal"/>
                                    </td>
                                    <td  align="left" valign="top">
                                        <s:password name="confPassword" id="confPassword" maxLength="70" cssStyle="width:140px"/>
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle">
                                    <td valign="top" align="center" colspan="2">
                                        <img align="middle" src="<s:url value="/img/horizontall.gif" includeParams="none"/>" />
                                        <br/><br/>
                                    </td>
                                </tr>
                                <tr valign="middle" align="right">
                                    <td>
                                    </td>
                                    <td align = "left">
                                        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                        <input type="submit" align="right" alt="Continue" value="Contnue"/>
                                        <br/><br/><br/><br/><br/><br/><br/>
                                    </td>
                                </tr>
                                <tr valign="top" class="footer">
                                    <td colspan="3">
                                        <br />
                                        <p id="footerNav"><a >RWI에 대하여</a> | <a >커리어</a> | <a >개인 정보, 보안 및 법적 보호</a> | <a >이메일 사기 신고</a> | <a >다양성 및 접근성</a>  <br /><a >거래에 관한 중요 공지</a> | <a >온라인 접근성 선언 (2008/03/06) </a> | <a >사이트 맵</a></p>
                                    </td>
                                </tr>
                            </s:form>
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
</body>
</html>
