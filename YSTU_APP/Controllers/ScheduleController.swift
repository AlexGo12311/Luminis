//
//  ScheduleController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 10.09.2024.
//

import UIKit

final class ScheduleController: BaseController {
    
    private let navBar = ScheduleNavBar()
    private var lessons: [Lesson] = []
    
    let scheduleFeedTable: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ScheduleTableViewCell.self, forCellReuseIdentifier: ScheduleTableViewCell.identifier)
        table.backgroundColor = AccentColors.bgColor
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.delegate = self
//        getGruopList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navBar.scrollToCurrentWeek()
        navBar.selectToday()
        addRightBorder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.layer.cornerRadius = 24
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        setShadow(navBar)
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 134 + view.safeAreaInsets.top)
        ])
    }
    
    func addRightBorder() {
//        scheduleFeedTable.layer.sublayers?.forEach {
//                if $0.backgroundColor == AccentColors.normalColor.withAlphaComponent(0.2).cgColor {
//                    $0.removeFromSuperlayer()
//                }
//            }
        
        let rightBorder = CALayer()
        let borderX: CGFloat = 86 - 2 // Позиция по X
        let borderY: CGFloat = 10 + (scheduleFeedTable.tableHeaderView?.frame.height ?? 0) // Позиция по Y
        let borderHeight = scheduleFeedTable.contentSize.height - borderY - 48 // Высота границы (same like bottom anchor)

        
        rightBorder.backgroundColor = AccentColors.normalColor.withAlphaComponent(0.2).cgColor
        rightBorder.frame = CGRect(x: borderX, y: borderY, width: 2, height: borderHeight)
        scheduleFeedTable.layer.addSublayer(rightBorder)

        // Создаем верхнюю точку
        let topDot = CALayer()
        topDot.backgroundColor = AccentColors.normalColor.cgColor
        topDot.cornerRadius = 3 // Делаем круглую точку
        topDot.frame = CGRect(x: rightBorder.frame.origin.x - 2, y: rightBorder.frame.origin.y - 3, width: 6, height: 6)
        scheduleFeedTable.layer.addSublayer(topDot)

        // Создаем нижнюю точку
        let bottomDot = CALayer()
        bottomDot.backgroundColor = AccentColors.normalColor.cgColor
        bottomDot.cornerRadius = 3 // Делаем круглую точку
        bottomDot.frame = CGRect(x: rightBorder.frame.origin.x - 2, y: rightBorder.frame.origin.y + rightBorder.frame.height - 3, width: 6, height: 6)
        scheduleFeedTable.layer.addSublayer(bottomDot)
    }
    
    private func getSchedule(for date: Date) {
        APICaller.shared.getSchedule(for: date) { result in
            switch result {
            case .success(let lessons):
                // Обновляем UI с полученными уроками
                self.updateUI(with: lessons)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    private func updateUI(with lessons: [Lesson]) {
        print("Updating UI with \(lessons.count) lessons")
        self.lessons = lessons
        DispatchQueue.main.async {
            if lessons.isEmpty {
                // Показываем сообщение, что расписание пустое
                if let sublayers = self.scheduleFeedTable.layer.sublayers {
                    for sublayer in sublayers {
                        sublayer.isHidden = true
                    }
                }
                let label = UILabel(frame: self.scheduleFeedTable.bounds)
                label.text = "No lessons for this day"
                label.textAlignment = .center
                label.textColor = .gray
                self.scheduleFeedTable.backgroundView = label
            } else {
                if let sublayers = self.scheduleFeedTable.layer.sublayers {
                    for sublayer in sublayers {
                        sublayer.isHidden = false
                    }
                }
                self.scheduleFeedTable.backgroundView = nil
            }
            self.scheduleFeedTable.reloadData()
        }
    }
    
    private func getGruopList() {
        APICaller.shared.getGroupsList { results in
            switch results {
            case .success(let items):
                print(items)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func addHeaderView() {
        let header = ScheduleHeader(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        scheduleFeedTable.tableHeaderView = header
    }
    
    override func addViews() {
        super.addViews()
        view.addSubview(scheduleFeedTable)
        view.addSubview(navBar)
    }
    
    override func layoutViews() {
        super.layoutViews()
        addHeaderView()
        scheduleFeedTable.translatesAutoresizingMaskIntoConstraints = false
        scheduleFeedTable.contentInsetAdjustmentBehavior = .never
         
        NSLayoutConstraint.activate([
            scheduleFeedTable.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -12),
            scheduleFeedTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scheduleFeedTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scheduleFeedTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
        ])
    }
    
    override func configure() {
        super.configure()
        scheduleFeedTable.delegate = self
        scheduleFeedTable.dataSource = self
        scheduleFeedTable.estimatedRowHeight = 137 // Примерное значение для улучшения производительности
        scheduleFeedTable.rowHeight = UITableView.automaticDimension
        scheduleFeedTable.showsVerticalScrollIndicator = false
        scheduleFeedTable.showsHorizontalScrollIndicator = false
    }
    
    
}

extension ScheduleController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return lessons.count // Количество строк равно количеству уроков
        }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleTableViewCell.identifier, for: indexPath) as? ScheduleTableViewCell else {
            return UITableViewCell()
        }
        
        let lesson = lessons[indexPath.row] // Исправлено с indexPath.section на indexPath.row
//        print("Configuring cell with lesson: \(lesson)")
        cell.configureTimeView(start: lesson.startAt ?? "", end: lesson.endAt ?? "")
        cell.configureCourseView(name: lesson.lessonName ?? "", type: "Лекция", room: lesson.auditoryName ?? "", teacher: lesson.teacherName ?? "")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16 // Создаст отступ перед секцией, тем самым увеличив расстояние между ячейками
    }
}


extension ScheduleController: ScheduleNavBarDelegate {
    func didSelectDay(_ date: Date) {
        self.getSchedule(for: date)
    }
}

