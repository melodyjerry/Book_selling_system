<%@ page language="java"
	import="java.util.*, models.ManagerDao, org.json.JSONArray, org.json.JSONObject"
	pageEncoding="UTF-8"%>
<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort()
			+ path + "/";
%>
<%
	String mname = null;
	String passwd = null;
	Cookie[] cookies = request.getCookies(); // 获取 cookies

	if (cookies == null) { // 如果没有 cookies，重定向到 index.jsp
		response.sendRedirect("index.jsp");
		return;
	}

	for (int i = 0; i < cookies.length; i++) { // 获取 cookies 中的 mname 和 passwd
		if ("mname".equals(cookies[i].getName()))
			mname = cookies[i].getValue();
		if ("passwd".equals(cookies[i].getName()))
			passwd = cookies[i].getValue();
	}

	if (mname != null && passwd != null) {
		ManagerDao managerDao = new ManagerDao();

		String managerJsonString = managerDao.search_manager(new String[]{"PASSWD"}, "MNAME", mname, -1);
		JSONArray managerJsonArray = new JSONArray(managerJsonString);
		if (managerJsonArray.length() != 1) { // 如果找不到该用户名，重定向到 index.jsp
			response.sendRedirect("index.jsp");
			return;
		}
		JSONObject managerJsonObject = managerJsonArray.getJSONObject(0);
		if (!passwd.equals(managerJsonObject.getString("PASSWD"))) { // 如果 passwd 与数据库中的 passwd 不相同，重定向到 index.jsp
			response.sendRedirect("index.jsp");
			return;
		}
	} else // 如果没有指定 cookie，重定向页面到 index.jsp
		response.sendRedirect("index.jsp");
%>

<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8" />
<title>图书销售系统 | 会员管理</title>
<link rel="stylesheet" href="css/style.css" />
<style>
#result li .column4 {
	position: relative;
	top: 20px;
	width: 25%;
	min-width: 160px;
}

#result li .column1 {
	width: 50%;
}

#record-window {
	position: fixed;
	left: 50%;
	top: 50%;
	transform: translate(-50%, -50%);
	display: none;
	background-color: white;
	border-radius: 9px;
}
</style>
<script src="js/main.js"></script>
<script>
	var page = 1;
	var pageNumber = 0;
	var returnFirstPage = true;

	window.onload = function() {
		var searchInput = document.getElementById("search_input");
		var selectButton = document.getElementById("select");
		var oLi = document.querySelectorAll("nav>ul li");
		var addButton = document.querySelector(".add");
		var prevPage = document.getElementById("prev-page");
		var nextPage = document.getElementById("next-page");

		for (var i = 0; i < oLi.length; i++) {
			oLi[i].onclick = redirect;
		}

		selectButton.onclick = search;
		searchInput.onkeypress = function(eOb) {
			if (eOb.keyCode == 13)
				// 判断是否为回车键
				search();
		};

		addButton.onclick = addMember;

		prevPage.onclick = function() {
			if (page > 1) {
				page--;
				returnFirstPage = false;
				search();
				returnFirstPage = true;
			}
		}
		nextPage.onclick = function() {
			if (page < pageNumber) {
				page++;
				returnFirstPage = false;
				search();
				returnFirstPage = true;
			}
		}
	};

	function search() {
		var searchInput = document.getElementById("search_input");

		var value = searchInput.value;
		if (value) {
			if (returnFirstPage)
				page = 1;

			var xmlHttpRequest = new XMLHttpRequest();

			xmlHttpRequest.open("POST", "Member_search", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send("value=" + value + "&page=" + page);

			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var oUl = document.querySelector("div#result>ul");
					var oPager = document.querySelector("#pager");
					var jsonObj = JSON.parse(xmlHttpRequest.responseText);

					pageNumber = jsonObj[jsonObj.length - 1]["PAGE_SUM"];
					oPager.querySelector("span").innerHTML = page + " / " + pageNumber;
					jsonObj = jsonObj.slice(0, -1);

					if (Number(pageNumber) > 1) // 如果总页数大于 1，
						oPager.style.display = "block";
					else
						oPager.style.display = "none";

					oUl.innerHTML = "";
					for (var i = 0; i < jsonObj.length; i++) {
						var liHTML = '<li><div class="column1"><h1>';

						liHTML += jsonObj[i]["MNAME"] + "</h1>";
						liHTML += "<p>电话号码：" + jsonObj[i]["PHONE_NUMBER"] + "</p>";
						liHTML += "<p>身份证号码：" +
							jsonObj[i]["IDENTIFICATION_NUMBER"] +
							"</p>";
						liHTML += "<p>会员组：" + jsonObj[i]["MGNAME"] + "</p>";
						liHTML += '</div><div class="column2">';
						liHTML += "<p>购书数量：" + "</p>";
						liHTML += "<p>余额：" + "</p>";
						liHTML += "<p>状态：" + "</p>";
						liHTML += '</div><div class="column3">';
						liHTML += "<p>" + jsonObj[i]["BOOK_PURCHASE"] + "</p>";
						liHTML += "<p>" + jsonObj[i]["BALANCE"] + "</p>";
						if (jsonObj[i]["STATUS"] == 1)
							liHTML += "<p>正常</p>";
						else
							liHTML += "<p>已挂失</p>";
						liHTML += '</div><div class="column4"><button type="button" class="modify-info-button">修改资料</button><button type="button" class="modify-passwd-button">修改密码</button><br><button type="button" class="recharge-button">充值</button><button type="button" class="loss-button">';
						if (jsonObj[i]["STATUS"] == 1)
							liHTML += "挂失";
						else
							liHTML += "解挂";
						liHTML += '</button><button type="button" class="delete-button">删除</button><br><button type="button" class="purchase-record-button">查看最近购书记录</button></div></li>';

						oUl.innerHTML += liHTML;
					}
					var modifyInfoButton = document.getElementsByClassName("modify-info-button");
					for (var j = 0; j < modifyInfoButton.length; j++)
						modifyInfoButton[j].onclick = modifyInfo;
					var modifyPasswdButton = document.getElementsByClassName("modify-passwd-button");
					for (var j = 0; j < modifyPasswdButton.length; j++)
						modifyPasswdButton[j].onclick = modifyPasswd;
					var rechargeButton = document.getElementsByClassName("recharge-button");
					for (var j = 0; j < rechargeButton.length; j++)
						rechargeButton[j].onclick = recharge;
					var lossButton = document.getElementsByClassName("loss-button");
					for (var j = 0; j < lossButton.length; j++) {
						if (lossButton[j].innerHTML == "挂失")
							lossButton[j].onclick = reportLoss;
						else
							lossButton[j].onclick = releaseLoss;
					}
					var deleteButton = document.getElementsByClassName("delete-button");
					for (var j = 0; j < deleteButton.length; j++)
						deleteButton[j].onclick = deleteMember;
					var purchaseRecordButton = document.getElementsByClassName("purchase-record-button");
					for (var j = 0; j < purchaseRecordButton.length; j++)
						purchaseRecordButton[j].onclick = searchPurchaseRecord;
				}
			};
		}
	}

	function addMember() {
		var layer = document.getElementById("layer");
		var addWindow = layer.querySelector("#add-member");
		var oInput = addWindow.querySelectorAll("input");
		var confirmButton = addWindow.querySelector(".confirm");
		var cancelButton = addWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		addWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			addWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			for (var i = 0; i < oInput.length; i++)
				if (!oInput[i].value)
					return;
					
			var oSpan = failMessage.querySelector("span");
			if (oInput[4].value != oInput[5].value) {
				oSpan.innerHTML = "两次输入的密码不一致";
				addWindow.style.display = "none";
				failMessage.style.display = "block";
				setTimeout(function() {
					failMessage.style.display = "none";
					addWindow.style.display = "block";
				}, 2000);
				return;
			}

			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_insert", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"mname=" + oInput[0].value + "&phone_number=" + oInput[1].value + "&identification=" + oInput[2].value + "&members_group=" + oInput[3].value + "&passwd=" + oInput[4].value
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "注册成功";
						addWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);
					} else {
						oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						addWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							addWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function modifyInfo() {
		var currentItem = this.parentElement.parentElement;
		var mname = currentItem.querySelector(".column1>h1").innerHTML;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);
		var identification = currentItem.querySelector(".column1>p:nth-child(3)").innerHTML;
		identification = identification.slice(6, identification.length);

		var layer = document.getElementById("layer");
		var modifyWindow = layer.querySelector("#modify-information");
		var oInput = modifyWindow.querySelectorAll("input");
		var confirmButton = modifyWindow.querySelector(".confirm");
		var cancelButton = modifyWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		oInput[0].value = mname;
		oInput[1].value = phoneNumber;
		oInput[2].value = identification;
		layer.style.display = "block";
		modifyWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			modifyWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			if (!oInput[0].value || !oInput[1].value || !oInput[2].value)
				return;

			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_modify", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"option=1&phone_number=" + phoneNumber + "&mname=" + oInput[0].value +
				"&new_phone_number=" + oInput[1].value + "&identification=" + oInput[2].value
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "修改成功";
						modifyWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);

						/* 前端同步更新 */
						currentItem.querySelector(".column1>h1").innerHTML = oInput[0].value;
						currentItem.querySelector(".column1>p:nth-child(2)").innerHTML = "电话号码：" + oInput[1].value;
						currentItem.querySelector(".column1>p:nth-child(3)").innerHTML = "身份证号码：" + oInput[2].value;
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						modifyWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							modifyWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function modifyPasswd() {
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var modifyWindow = layer.querySelector("#modify-passwd");
		var oInput = modifyWindow.querySelectorAll("input");
		var confirmButton = modifyWindow.querySelector(".confirm");
		var cancelButton = modifyWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		modifyWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			modifyWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			if (!oInput[0].value || !oInput[1].value || !oInput[2].value)
				return;

			var oSpan = failMessage.querySelector("span");
			if (oInput[1].value != oInput[2].value) {
				oSpan.innerHTML = "两次输入的密码不一致";
				modifyWindow.style.display = "none";
				failMessage.style.display = "block";
				setTimeout(function() {
					failMessage.style.display = "none";
					modifyWindow.style.display = "block";
				}, 2000);
				return;
			}

			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_modify", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"option=5&phone_number=" + phoneNumber + "&old_passwd=" + oInput[0].value +
				"&new_passwd=" + oInput[1].value
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "修改成功";
						modifyWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						modifyWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							modifyWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function recharge() {
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var rechargeWindow = layer.querySelector("#recharge");
		var confirmButton = rechargeWindow.querySelector(".confirm");
		var cancelButton = rechargeWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		rechargeWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			rechargeWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			var oInput = document.querySelector("#recharge>input");

			if (!oInput.value)
				return;

			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_modify", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"option=2&phone_number=" + phoneNumber + "&recharge_amount=" + oInput.value
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "充值成功";
						rechargeWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);

						/* 前端同步更新 */
						var balanceItem = currentItem.querySelector(".column3>p:nth-child(2)");
						balanceItem.innerHTML = Number(balanceItem.innerHTML) + Number(oInput.value);
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						rechargeWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							rechargeWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function reportLoss() {
		var thisButton = this;
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var reportLossWindow = layer.querySelector("#report-loss");
		var confirmButton = reportLossWindow.querySelector(".confirm");
		var cancelButton = reportLossWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		reportLossWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			reportLossWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_modify", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"option=3&phone_number=" + phoneNumber
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						thisButton.innerHTML = "解挂";
						thisButton.onclick = releaseLoss;
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "挂失成功";
						reportLossWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);

						/* 前端同步更新 */
						currentItem.querySelector(".column3>p:nth-child(3)").innerHTML = "已挂失";
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						reportLossWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							reportLossWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function releaseLoss() {
		var thisButton = this;
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var releaseLossWindow = layer.querySelector("#release-loss");
		var confirmButton = releaseLossWindow.querySelector(".confirm");
		var cancelButton = releaseLossWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		releaseLossWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			releaseLossWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_modify", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"option=4&phone_number=" + phoneNumber
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						thisButton.innerHTML = "挂失";
						thisButton.onclick = reportLoss;
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "已解除挂失";
						releaseLossWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);

						/* 前端同步更新 */
						currentItem.querySelector(".column3>p:nth-child(3)").innerHTML = "正常";
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						releaseLossWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							releaseLossWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function deleteMember() {
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var deleteWindow = layer.querySelector("#delete");
		var confirmButton = deleteWindow.querySelector(".confirm");
		var cancelButton = deleteWindow.querySelector(".cancel");
		var successMessage = layer.querySelector(".success-message");
		var failMessage = layer.querySelector(".fail-message");

		layer.style.display = "block";
		deleteWindow.style.display = "block";

		cancelButton.onclick = function() {
			layer.style.display = "none";
			deleteWindow.style.display = "none";
		}

		confirmButton.onclick = function() {
			var xmlHttpRequest = new XMLHttpRequest();
			xmlHttpRequest.open("POST", "Member_delete", true);
			xmlHttpRequest.setRequestHeader(
				"Content-Type",
				"application/x-www-form-urlencoded"
			);
			xmlHttpRequest.send(
				"phone_number=" + phoneNumber
			);
			xmlHttpRequest.onreadystatechange = function() {
				if (
					xmlHttpRequest.readyState == 4 &&
					xmlHttpRequest.status == 200
				) {
					var returnMessage = JSON.parse(xmlHttpRequest.responseText)["message"];
					if (returnMessage === "success") {
						var oSpan = successMessage.querySelector("span");
						oSpan.innerHTML = "删除成功";
						deleteWindow.style.display = "none";
						successMessage.style.display = "block";
						setTimeout(function() {
							successMessage.style.display = "none";
							layer.style.display = "none";
						}, 1000);

						/* 前端同步更新 */
						currentItem.style.display = "none";
					} else {
						var oSpan = failMessage.querySelector("span");
						oSpan.innerHTML = returnMessage;
						deleteWindow.style.display = "none";
						failMessage.style.display = "block";
						setTimeout(function() {
							failMessage.style.display = "none";
							deleteWindow.style.display = "block";
						}, 2000);
					}
				}
			};
		}
	}

	function searchPurchaseRecord() {
		var currentItem = this.parentElement.parentElement;
		var phoneNumber = currentItem.querySelector(".column1>p:nth-child(2)").innerHTML;
		phoneNumber = phoneNumber.slice(5, phoneNumber.length);

		var layer = document.getElementById("layer");
		var failMessage = layer.querySelector(".fail-message");
		var recordWindow = layer.querySelector("#record-window");
		var tableWindow = layer.querySelector("#record-window>.table-window");

		var xmlHttpRequest = new XMLHttpRequest();
		xmlHttpRequest.open("POST", "Member_purchase_record_search", true);
		xmlHttpRequest.setRequestHeader(
			"Content-Type",
			"application/x-www-form-urlencoded"
		);
		xmlHttpRequest.send(
			"phone_number=" + phoneNumber
		);
		xmlHttpRequest.onreadystatechange = function() {
			if (
				xmlHttpRequest.readyState == 4 &&
				xmlHttpRequest.status == 200
			) {
				var jsonObj = JSON.parse(xmlHttpRequest.responseText);
				if (jsonObj.length > 0) {
					var tableHtml = '<table><tr><th>购买日期</th><th>书名</th><th>作者</th><th>数量</th><th>单价</th></tr>';
					for (var i = 0; i < jsonObj.length && i < 10; i++)
						tableHtml += '<tr><td>' + jsonObj[i]["DATE_OF_SALE"]
							+ '</td><td>' + jsonObj[i]["TITLE"]
							+ '</td><td>' + jsonObj[i]["AUTHOR"]
							+ '</td><td>' + jsonObj[i]["QUANTITY"]
							+ '</td><td>' + jsonObj[i]["PRICE"]
							+ '</td></tr>';
					tableHtml += '</table>';
					tableWindow.innerHTML = tableHtml;

					layer.style.display = "block";
					recordWindow.style.display = "block";

					var layerOnclick = function() { // 定义一个事件处理程序
						layer.style.display = "none";
						recordWindow.style.display = "none";
						layer.removeEventListener("click", layerOnclick, false); // 点击 layer 后立即移除此事件
					}

					layer.addEventListener("click", layerOnclick, false); // 添加 click 事件
				} else {
					var oSpan = failMessage.querySelector("span");
					oSpan.innerHTML = "该会员无购书记录";
					layer.style.display = "block";
					failMessage.style.display = "block";
					setTimeout(function() {
						layer.style.display = "none";
						failMessage.style.display = "none";
					}, 1000);
				}
			}
		}
	}
</script>
</head>
<body>
	<header>
		<h1>
			<img src="images/logo-line.png"> 图书销售系统
		</h1>
		<input type="text" name="search_input" id="search_input"
			placeholder="输入姓名、电话 或 身份证号" />
		<button type="button" id="select">查询</button>
	</header>
	<nav>
		<ul>
			<div>
				<li>图书出售</li>
				<li>零售退货</li>
				<li class="current">会员管理</li>
			</div>
			<div>
				<li>图书管理</li>
				<li>出版社管理</li>
				<li>会员组管理</li>
				<li>打印报表</li>
			</div>
			<div>
				<li>系统设置</li>
			</div>
		</ul>
	</nav>
	<main>
		<button type="button" class="add">＋ 会员注册</button>
		<div id="result">
			<ul></ul>
		</div>
		<div id="pager">
			<button type="button" id="prev-page">← 上一页</button>
			<span></span>
			<button type="button" id="next-page">下一页 →</button>
		</div>
	</main>
	<div id="layer">
		<div class="form-window" id="add-member">
			<h1>会员注册</h1>
			<span>姓名</span> <input type="text" /> <span>电话号码</span> <input
				type="text" /> <span>身份证号码</span> <input type="text" /> <span>会员组</span><input
				type="text" /> <span>密码</span> <input type="password" /><span>确认密码</span>
			<input type="password" />
			<button type="button" class="confirm">注册</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="form-window" id="modify-information">
			<h1>会员资料修改</h1>
			<span>姓名</span> <input type="text" /> <span>电话号码</span> <input
				type="text" /> <span>身份证号码</span> <input type="text" />
			<button type="button" class="confirm">修改</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="form-window" id="modify-passwd">
			<span>旧密码</span> <input type="password" /> <span>新密码</span> <input
				type="password" /> <span>确认密码</span> <input type="password" />
			<button type="button" class="confirm">修改</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="form-window" id="recharge">
			<span>金额</span> <input type="number" min="1" />
			<button type="button" class="confirm">充值</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="alert-window" id="report-loss">
			<p>
				<img src="images/alert.png"> 确定要挂失吗
			</p>
			<button type="button" class="confirm">确定</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="alert-window" id="release-loss">
			<p>
				<img src="images/alert.png"> 确定解除挂失吗
			</p>
			<button type="button" class="confirm">确定</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div class="alert-window" id="delete">
			<p>
				<img src="images/alert.png"> 确定删除该会员吗
			</p>
			<button type="button" class="confirm">确定</button>
			<button type="button" class="cancel">取消</button>
		</div>
		<div id="record-window">
			<div class="table-window"></div>
		</div>
		<div class="success-message">
			<img src="images/completed.png"> <span></span>
		</div>
		<div class="fail-message">
			<img src="images/error.png"> <span></span>
		</div>
	</div>
</body>
</html>
