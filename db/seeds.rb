User.create!(name:  "管理者",
             email: "email@sample.com",
             affiliation:           "管理職",
             employee_number:       9999,
             uid:                   "9999",
             password:              "password",
             password_confirmation: "password",
             admin: true)

AB = ["A", "B"]

# 一般ユーザー
2.times do |n|
  name = "一般" + AB[n]
  email = "email#{n+1}@sample.com"
  affiliation = "一般職"
  startTime = "9:00"
  endTime = "18:00"
  password = "password"
  User.create!(name:  name,
               email: email,
               affiliation:           affiliation,
               employee_number:       (n+1).to_s*4,
               uid:                   (n+1).to_s*4,
               designated_work_start_time: startTime,
               designated_work_end_time: endTime,
               password:              password,
               password_confirmation: password)
end

# 上司ユーザー
2.times do |n|
  name = "上司" + AB[n]
  email = "email#{n+3}@sample.com"
  affiliation = "役人職"
  startTime = "9:00"
  endTime = "18:00"
  password = "password"
  User.create!(name:  name,
               email: email,
               affiliation:           affiliation,
               employee_number:       (n+3).to_s*4,
               uid:                   (n+3).to_s*4,
               designated_work_start_time: startTime,
               designated_work_end_time: endTime,
               superior:              true,
               password:              password,
               password_confirmation: password)
end