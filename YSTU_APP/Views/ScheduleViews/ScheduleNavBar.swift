//
//  OverviewNavBar.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 29.09.2024.
//

protocol ScheduleNavBarDelegate: AnyObject {
    func didSelectDay(_ date: Date)
}

import UIKit

final class ScheduleNavBar: UIView {
    func addChooseGroupButtonAction(_ action: Selector, with: Any?) {
        chooseGroupButton.addTarget(with, action: action, for: .touchUpInside)
    } 
    
    
    private let currentDate = Date()
    private var selectedWeekIndex: Int?
    private var selectedDayIndex: Int?
    
    private var lastContentOffset: CGFloat = 0
    
    weak var delegate: ScheduleNavBarDelegate?


    // Начало года 1 января в данном случае
    private let baseDate: Date = {
        var calendar = Calendar.current
        
        let startDateOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
        let startDateOfWeek = calendar.dateInterval(of: .weekOfYear, for: startDateOfYear)!.start
        
        return startDateOfWeek
    }()
    
    private var weeks = [Week]()
    
    let weekView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isPagingEnabled = true
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    init() {
        super.init(frame: .zero)
        setupLayout()
        fetchAndConfigureContextMenu()
        for i in 0..<100 {
            if let startDate = Calendar.current.date(byAdding: .weekOfYear, value: i, to: baseDate) {
                weeks.append(Week(startDate: startDate))
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func scrollToCurrentWeek() {
        if let currentWeekIndex = getCurrentWeekIndex() {
            let totalItems = self.weekView.numberOfItems(inSection: 0)
            if currentWeekIndex >= 0 && currentWeekIndex < totalItems {
                let indexPath = IndexPath(item: currentWeekIndex, section: 0)
                let layoutAttributes = self.weekView.layoutAttributesForItem(at: indexPath)
                
                if let attributes = layoutAttributes {
                    let targetOffset = CGPoint(x: attributes.frame.origin.x, y: 0)
                    self.weekView.setContentOffset(targetOffset, animated: true)
                }
            }
        }
    }
    
    func selectToday() {
        guard let currentWeekIndex = getCurrentWeekIndex(),
              let currentDayIndex = getCurrentDayIndexInWeek(currentWeekIndex) else {
            return
        }
        
        selectedWeekIndex = currentWeekIndex
        selectedDayIndex = currentDayIndex
        
        // Обновите текущую ячейку после прокрутки
        DispatchQueue.main.async {
            self.weekView.reloadData()
            self.todayLabel.text = "Today"
            self.currentDateLabel.text = self.setTodayDateToLabel()
        }
    }
    
    
    private func getCurrentWeekIndex() -> Int? {
        let calendar = Calendar.current
        // разница начала и конца
        let components = calendar.dateComponents([.weekOfYear], from: baseDate, to: Date())
        guard let weekIndex = components.weekOfYear else { return nil }
        
        return weekIndex
    }
    
    private func getCurrentDayIndexInWeek(_ weekIndex: Int) -> Int? {
        let calendar = Calendar.current
        let currentDate = Date()
        
        guard let startDateOfWeek = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: baseDate) else {
            return nil
        }
        
        let dayIndex = calendar.dateComponents([.day], from: startDateOfWeek, to: currentDate).day
        return (dayIndex ?? 0) >= 0 && (dayIndex ?? 0) < 7 ? dayIndex : nil
    }

    
    private func getDatesForWeek(startDate: Date) -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    let chooseGroupButton = ChoosyButton(groupName: "ЦПИ-11")
    
    func fetchAndConfigureContextMenu() {
        APICaller.shared.getGroupsList { [weak self] result in
            switch result {
            case .success(let sections):
                DispatchQueue.main.async {
                    self?.updateMenu(sections: sections)
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    func updateMenu(sections: [GroupSection]) {
        configureContextMenu(with: sections)
    }

    
    func configureContextMenu(with data: [GroupSection]) {
        // Показать временное меню, пока данные не загружены
        chooseGroupButton.menu = UIMenu(title: "Loading...", children: [])
        
        // Асинхронное создание меню
        DispatchQueue.global().async {
            let menus = data.map { section in
                let actions = section.groups.map { group in
                    UIAction(title: group) { [weak self] _ in
                        self?.chooseGroupButton.changeGroupName(group)
                        self?.layoutIfNeeded()
                    }
                }
                return UIMenu(title: section.title, children: actions)
            }
            
            
            let mainMenu = UIMenu(children: menus)
            
            // Обновление меню на основном потоке
            DispatchQueue.main.async { [weak self] in
                self?.chooseGroupButton.menu = mainMenu
                self?.chooseGroupButton.showsMenuAsPrimaryAction = true
            }
        }
    }

    
    let todayLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 20)
        label.textColor = AccentColors.ordinaryTextColor
        label.text = "Today"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setTodayDateToLabel() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"  // Формат даты: Apr 08, 2022
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let date = Date()  // Текущая дата
        return String(dateFormatter.string(from: date))
    }
    
    let currentDateLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Light.size(of: 14)
        label.textColor = AccentColors.ordinaryTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
}

extension ScheduleNavBar {
    func setupLayout() {
        addViews()
        configure()
    }
    
    func addViews() {
        addSubview(chooseGroupButton)
        addSubview(currentDateLabel)
        addSubview(todayLabel)
        addSubview(weekView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Group choose button
        NSLayoutConstraint.activate([
            chooseGroupButton.topAnchor.constraint(equalTo: topAnchor, constant: 6 + safeAreaInsets.top),
            chooseGroupButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chooseGroupButton.heightAnchor.constraint(equalToConstant: 30),
            chooseGroupButton.widthAnchor.constraint(equalToConstant: 96)
        ])
        
        // CurrentDate label
        NSLayoutConstraint.activate([
            currentDateLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            currentDateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 1 + safeAreaInsets.top)
        ])
        
        // Today Label
        NSLayoutConstraint.activate([
            todayLabel.topAnchor.constraint(equalTo: currentDateLabel.bottomAnchor, constant: 4),
            todayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ])
        
        // Week view
        NSLayoutConstraint.activate([
            weekView.topAnchor.constraint(equalTo: todayLabel.bottomAnchor, constant: 8),
            weekView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            weekView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            weekView.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    
    func configure() {
        weekView.register(WeekCell.self, forCellWithReuseIdentifier: WeekCell.identifier)
        weekView.dataSource = self
        weekView.delegate = self
        
        backgroundColor = AccentColors.interfaceColor
        setShadow(chooseGroupButton)
        chooseGroupButton.translatesAutoresizingMaskIntoConstraints = false
    }
}

extension ScheduleNavBar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weeks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeekCell.identifier, for: indexPath) as? WeekCell else { return UICollectionViewCell() }
        
//        let week = weeks[indexPath.item]
//        let dates = getDatesForWeek(startDate: week.startDate)
        
        let offset = indexPath.item
        let newStartDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: baseDate) ?? Date()
        
        let dates = getDatesForWeek(startDate: newStartDate)
        
        let todayWeekIndex = getCurrentWeekIndex()
        let todayIndex = getCurrentDayIndexInWeek(todayWeekIndex ?? 0) ?? 0
        
        cell.configure(with: dates, selectedWeekIndex: selectedWeekIndex, selectedDayIndex: selectedDayIndex, currentWeekIndex: indexPath.item, todayIndex: todayIndex, todayWeekIndex: todayWeekIndex ?? 0)
            cell.delegate = self
            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.frame.width
        let cellHeight = collectionView.frame.height
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let visibleIndexPath = weekView.indexPathsForVisibleItems.first else { return }
        let currentWeekIndex = visibleIndexPath.item

        // Проверка на изменение направления: вправо или влево
        if (selectedWeekIndex ?? 0) < currentWeekIndex {
            didScrollRight(currentWeekIndex: currentWeekIndex)
        }
        
        else if (selectedWeekIndex ?? 0) > currentWeekIndex {
            // Скролл влево
            didScrollLeft(currentWeekIndex: currentWeekIndex)
        }

    }


    func didScrollRight(currentWeekIndex: Int) {
        guard let cell = weekView.cellForItem(at: IndexPath(item: currentWeekIndex, section: 0)) as? WeekCell else { return }
        print("left")
        
        // Добавляем анимацию для скролла вправо
        cell.leadingConstraint.isActive = true
        cell.trailingConstraint.isActive = false
    }

    func didScrollLeft(currentWeekIndex: Int) {
        guard let cell = weekView.cellForItem(at: IndexPath(item: currentWeekIndex, section: 0)) as? WeekCell else { return }
        print("right")
        
        // Добавляем анимацию для скролла влево
        cell.leadingConstraint.isActive = false
        cell.trailingConstraint.isActive = true
    }


}


extension ScheduleNavBar: WeekCellDelegate {
    func dayButtonDidTapped(_ sender: DayButton) {
        selectedWeekIndex = nil
        selectedDayIndex = nil
        
        
        
        // Получаем текущий видимый индекс недели
        guard let visibleIndexPath = weekView.indexPathsForVisibleItems.first else { return }
        let currentWeekIndex = visibleIndexPath.item
        
        // Устанавливаем глобальные выбранные индексы
        selectedWeekIndex = currentWeekIndex
        selectedDayIndex = sender.tag
        
        let dates = getDatesForWeek(startDate: weeks[currentWeekIndex].startDate)
        let selectedDate = dates[selectedDayIndex ?? 0]
        print("Selected date: \(selectedDate)")
        delegate?.didSelectDay(selectedDate)
        
        // Перезагружаем данные всех ячеек
        weekView.reloadData()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"  // Формат даты: Apr 08, 2022
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        currentDateLabel.text = dateFormatter.string(from: selectedDate)
        
        guard let currentWeekIndex = getCurrentWeekIndex(),
              let currentDayIndex = getCurrentDayIndexInWeek(currentWeekIndex) else {
            return
        }
        
        let isSameWeek = currentWeekIndex == selectedWeekIndex
        let isPreviousWeek = (selectedWeekIndex ?? 0) < currentWeekIndex
        let isNextWeek = (selectedWeekIndex ?? 0) > currentWeekIndex
        
        let isNextDay = (selectedDayIndex ?? 0) - currentDayIndex == 1
        let isPreviousDay = currentDayIndex - (selectedDayIndex ?? 0) == 1
        let isSameDay = currentDayIndex == (selectedDayIndex ?? 0)
        let isNotAdjacent = !(isNextDay || isPreviousDay)
        

        if isSameWeek {
            if isNextDay {
                self.todayLabel.text = "Tomorrow"
            } else if isPreviousDay {
                self.todayLabel.text = "Yesterday"
            } else if isSameDay {
                self.todayLabel.text = "Today"
            } else if isNotAdjacent {
                self.todayLabel.text = "On week"
            }
        }
        
        if isPreviousWeek {
            self.todayLabel.text = "Last week"
        }
        
        if isNextWeek {
            self.todayLabel.text = "Next week"
        }
        
        
    }
}
