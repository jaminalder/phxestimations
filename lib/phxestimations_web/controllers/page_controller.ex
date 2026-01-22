defmodule PhxestimationsWeb.PageController do
  use PhxestimationsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
