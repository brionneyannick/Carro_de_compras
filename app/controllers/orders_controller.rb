class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.cart
    #@total = @orders.map { |order| order.product.price }.sum() otra forma de sumar sin inject
    @total = @orders.inject(0) { |total, order| total += order.product.price * order.quantity }
  end

  def create
    @previous_order = Order.find_by(user_id: current_user.id, product_id: params[:product_id], payed: false)
    if @previous_order.present?
      new_quantity = @previous_order.quantity + 1
      @previous_order.update(quantity: new_quantity)
    else
      @order = Order.new()
      @product = Product.find(params[:product_id])
      @order.product = @product
      @order.price = @product.price
      @order.user = current_user

      if @order.save
        redirect_to root_path, notice: "#{@order.product.name} ha sido agregado al carro!"
      else
        redirect_to root_path, alert: 'El producto NO ha sido agregado!'
      end
    end
  end

  def destroy
    @order = Order.find(params[:id])

    if @order.quantity == 1
      if @order.destroy
        redirect_to orders_path, notice: 'Carro Actualizado'
      else
        redirect_to orders_path, alert: 'Error al actualizar el carro'
      end
    elsif @order.quantity > 1
      @order.quantity -= 1
      if @order.save
        redirect_to orders_path, notice: 'Carro Actualizado'
      else
        redirect_to orders_path, alert: 'Error al actualizar el carro'
      end
    end
  end

  def empty_cart
    current_user.cart.destroy_all
    redirect_to orders_path, notice: 'El carrito ha sido vaciado'
  end
end
