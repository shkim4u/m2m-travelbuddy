<%@ include file="../common/moduleInclude.jsp" %>
<%@ page language="java" pageEncoding="UTF-8" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>RWI - Riches Wealth International <tiles:getAsString name="pageDesc"/></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Type" content="text/html" />
<script language="javascript">AC_FL_RunContent = 0;</script>
<script src="<s:url value="/js/AC_RunActiveContent.js"/>" language="javascript"></script>
<link rel="stylesheet" type="text/css" href="<s:url value="/css/details.css"/>" />
<link rel="shortcut icon" href="<s:url value="/img/favicon.ico"/>" />
</head>
<body>
<br />
<table cellpadding="0" cellspacing="0" id="content" border="2" align="center">
    <tr valign="mtop">
        <td colspan="2">
            <table cellpadding="0" cellspacing="0" border="0">
                <tr valign="middle">
                    <td id="utilities" align="right"><a href="/riches/">Bank Home</a> | <a href="<s:url action="FindLocations.action" includeParams="none"/>">위치 검색</a> | <a >담당자 문의</a> | <a >사이트 맵</a>&nbsp;</td>
                    <td id="search" align="right" >
                        <form id="search" action="" method="get" >
                            <input type="text" size="28" maxlength="75" name="query" id="searchbox" title="Search" height="24" align="absmiddle" />
                            <input type="image" src="<s:url value="/img/btn_search_white.gif" includeParams="none"/>" alt="Search" name="searchBtn" id="searchbtn"  align="absmiddle" disabled/>
                        </form>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
    <link rel="stylesheet" type="text/css" href="<s:url value="/css/rwi-2.css"/>" />
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

    <tr valign="top" width="100%">
        <td>
            <table cellpadding="0" cellspacing="0" border="0" width=100%>
                <tr valign="top">
                    <td valign="top" width="5%">
                    </td>
