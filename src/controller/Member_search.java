package controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import models.MembersDao;

/**
 * Servlet implementation class Member_search
 */
@WebServlet("/Member_search")
public class Member_search extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public Member_search() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		doPost(request, response);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.setCharacterEncoding("utf-8");
		response.setCharacterEncoding("utf-8");
		response.setContentType("application/json");

		String value = request.getParameter("value");

		String jsonString = null;
		MembersDao membersDao = new MembersDao();
		int page = Integer.valueOf(request.getParameter("page"));
		
		try {
			jsonString = membersDao.search_members(null, "ALL", value, page);
		} catch (ClassNotFoundException | SQLException e) {
			e.printStackTrace();
		}

		PrintWriter writer = response.getWriter();
		writer.write(jsonString);
		writer.close();
	}

}
