-- q1
db.getCollection("order").aggregate(
  [ { $limit : 30000 },
    {
      $lookup:
      {
        from: "customer",
        localField: "CustomerId",
        foreignField: "Id",
        as: "R1"
      }
    },
    {
      $lookup:
      {
        from: "prodcut",
        localField: "ProductId",
        foreignField: "ID",
        as: "R2"
      },
    },
    {
      "$project": {
        "FirstName": 1.0,
        "SecondName": 1.0,
        "product.name": 1.0
       
      }
    },
  ]
)

-- q2
db.getCollection("order").aggregate(
 [ { $limit : 30000 },
    {
      $lookup:
      {
        from: "customer",
        localField: "CustomerId",
        foreignField: "Id",
        as: "R1"
      },
       $lookup:
      {
        from: "deliveryMan",
        localField: "DeliveryManId",
        foreignField: "Id",
        as: "R2"
      },
    },
    {
      $project: {
        "customer.FirstName": 1.0,
       "customer.SecondName": 1.0,
      }
    },
  ]
)


--q3
db.getCollection("order").aggregate(
  [
    { $limit : 30000 },
    {
      $lookup:
      {
        from: "customer",
        localField: "CustomerId",
        foreignField: "Id",
        as: "R1"
      }
    },
    {
      $lookup:
      {
        from: "deliveryMan",
        localField: "DeliveryManId",
        foreignField: "Id",
        as: "R2"
      },
    },
     {
      $lookup:
      {
        from: "product",
        localField: "ProductId",
        foreignField: "Id",
        as: "R3"
      },
    },
    {
      $project: {
        "FirstName": 1.0,
        "SecondName": 1.0,
        "product.name":1.0,
        "deliveryMan.PhoneNumber":1.0
      }
    },
  ]
)


--q4
db.getCollection("order").aggregate(
  [
   { $limit : 30000 }, 
   { "$match": { "QuantityOrder":"7" }},
    {
      $lookup:
      {
        from: "customer",
        localField: "CustomerId",
        foreignField: "Id",
        as: "R1"
      }
    },{
      $lookup:
      {
        from: "deliveryMan",
        localField: "DeliveryManId",
        foreignField: "Id",
        as: "R2"
      },
    },
     {
      $lookup:
      {
        from: "product",
        localField: "ProductId",
        foreignField: "Id",
        as: "R2"
      },
    },
    {
      "$project": {
        "FirstName": 1.0,
        "SecondName": 1.0,
        "product.name":1.0,
        "deliveryMan.PhoneNumber":1.0
      }
    },
  ]
)