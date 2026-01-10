class PaymentModel {
  final int? id;
  final String? transactionId;
  final String? razorpayOrderId;
  final String? razorpaymentId;
  final String? orderNo;
  final String? totalAmount;
  final String? remainingAmount;

  final String? amount;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? paymentDate;
  final String? createdAtDate;
  final String? currency;

  final Customer? customer;

  PaymentModel({
    this.id,
    this.transactionId,
    this.razorpaymentId,
    this.razorpayOrderId,
    this.orderNo,
    this.totalAmount,
    this.remainingAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentDate,
    this.createdAtDate,
    this.currency,
    this.customer,
    this.amount,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      razorpayOrderId: json['razorpay_order_id'],
      amount: json['amount'].toString(),
      orderNo: json['order_no'],
      razorpaymentId: json['razorpay_payment_id'],
      totalAmount: json['total_amount'],
      remainingAmount: json['remaining_amount'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      paymentDate: json['payment_date'],
      createdAtDate: json['created_at_formatted'],
      currency: json['currency'],
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
    );
  }
}

class Customer {
  final int? id;
  final String? customerName;
  final String? mobileNo;
  final String? email;

  Customer({
    this.id,
    this.customerName,
    this.mobileNo,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerName: json['customer_name'],
      mobileNo: json['mobile_no'],
      email: json['email'],
    );
  }
}
