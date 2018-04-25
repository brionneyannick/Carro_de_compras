class ProductsController < ApplicationController
  def index
    if params[:buscar].present?
      @products = Product.where('name like ?', "%#{params[:buscar]}%")
    else
      @products = Product.all
    end
  end
end
