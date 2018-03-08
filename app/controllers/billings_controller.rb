class BillingsController < ApplicationController
  def pre_pay
    #Consultar carro de compra
    orders = current_user.cart

    #Cálculo de total
    total = orders.pluck("price * quantity").sum()

    #Generando array de hashes con los productos
    items = orders.map do |order|
      item = {}
      item[:name] = order.product.name
      item[:sku] = order.id.to_s
      item[:price] = order.price.to_s
      item[:currency] = 'USD'
      item[:quantity] = order.quantity
      item
    end

    payment = PayPal::SDK::REST::Payment.new({
      :intent =>  "sale",
      :payer =>  {
        :payment_method =>  "paypal" },
      :redirect_urls => {
        :return_url => "http://localhost:3000/billings/execute",
        :cancel_url => "http://localhost:3000/" },
      :transactions =>  [{
        :item_list => {
          :items => items},
        :amount =>  {
          :total =>  total.to_s,
          :currency =>  "USD" },
        :description =>  "This is the payment transaction description." }]}
    )

    if payment.create
      #redirije a PayPal
      redirect_url = payment.links.find{|v| v.method == "REDIRECT" }.href
      redirect_to redirect_url
    else
      payment.error
    end
  end#cierra prepay

  def execute
    paypal_payment = PayPal::SDK::REST::Payment.find(params[:paymentId])
      if paypal_payment.execute(payer_id: params[:PayerID])

        amount = paypal_payment.transactions.first.amount.total

        billing = Billing.create(
          user: current_user,
          code: paypal_payment.id,
          payment_method: 'paypal',
          amount: amount,
          currency: 'USD'
        )

        orders = current_user.orders.where(payed: false)
        orders.update_all(payed: true, billing_id: billing.id)

        redirect_to root_path, notice: 'La compra se realizó con éxito!'
      else
        render plain: 'No se pudo generar el cobro en paypal'
      end
  end
end
