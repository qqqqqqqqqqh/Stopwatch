//
//  ViewController.swift
//  testMVVM
//
//  Created by colin.qin on 2025/4/28.
//
import RxSwift
import RxCocoa
import UIKit
import SnapKit


class ViewController: UIViewController {
    private var disposeBag = DisposeBag()
    private let viewModel = StopwatchViewModel()
    
    let topView = UIView()
    // mid section
    let midView = UIView()
    let titleLabel = UILabel()
    let timeLabel = UILabel()
    let lapLabel = UILabel()
    
    // Middle buttons
    let lapResetButton = UIButton()
    let playPauseButton = UIButton()
    
    // Bottom table
    let tableView = UITableView()
    
    private var laps: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        tableView.dataSource = self
//        tableView.delegate = self
        // 自动创建需要注册
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "lapCell")

        tableView.reloadData()
        
        // 监听系统或应用内部的通知事件，在应用进入后台时触发自动保存
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: UIApplication.willResignActiveNotification,
            object: nil)

    }

    func setupUI() {
        // Configure top view
        view.addSubview(topView)
        topView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        topView.snp.makeConstraints { make in
                // make.top.equalTo(view.safeAreaLayoutGuide)
                make.left.right.equalToSuperview()
                make.height.equalTo(120)
        }
        topView.addSubview(titleLabel)
        titleLabel.text = "Stopwatch"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(75)
        }
        
        view.addSubview(midView)
//        topView.backgroundColor = .lightGray
        midView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
        }
        
        // Time label
        midView.addSubview(timeLabel)
        timeLabel.text = "00:00.00"
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .regular)
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        
        // Lap label
        midView.addSubview(lapLabel)
        lapLabel.text = "00:00.00"
        lapLabel.font = UIFont.systemFont(ofSize: 16)
        lapLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        // Buttons
        view.addSubview(lapResetButton)
        lapResetButton.setTitle("Lap", for: .normal)
        lapResetButton.backgroundColor = .systemGray
        lapResetButton.layer.cornerRadius = 35
        lapResetButton.snp.makeConstraints { make in
            make.top.equalTo(midView.snp.bottom).offset(20)
            make.centerX.equalToSuperview().offset(-80)
            make.width.height.equalTo(70)
        }
        
        view.addSubview(playPauseButton)
        playPauseButton.setTitle("Start", for: .normal)
        playPauseButton.backgroundColor = .systemGreen
        playPauseButton.layer.cornerRadius = 35
        playPauseButton.snp.makeConstraints { make in
            make.top.equalTo(midView.snp.bottom).offset(20)
            make.centerX.equalToSuperview().offset(80)
            make.width.height.equalTo(70)
        }
        
        // Table view
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(lapResetButton.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }

    }
    
    // MARK: - UI Settings
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    private func setupBindings() {

        viewModel.mainTime
            .drive(timeLabel.rx.text) // .drive使得mainTime变化时，timeLabel的text也变化
            .disposed(by: disposeBag)
        
        viewModel.lapTime
            .drive(lapLabel.rx.text)
            .disposed(by: disposeBag)
        
        // lap按钮是否可用，lapButtonEnabled->当mainTime不为00:00.00或isRunning为true时可用
        viewModel.lapButtonEnabled
            .drive(lapResetButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // lap按钮的标题变更（lap/reset）
        viewModel.lapButtonTitle
            .drive(lapResetButton.rx.title())
            .disposed(by: disposeBag)
        
        // paly按钮标题变更（play/stop）
        viewModel.playButtonTitle
            .drive(playPauseButton.rx.title())
            .disposed(by: disposeBag)
        
        // play按钮颜色变更
        viewModel.playButtonColor
            .drive(playPauseButton.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        // lapsSubject数据变化时，tableview重新加载
        viewModel.laps
            .drive(onNext: { [weak self] laps in
                self?.laps = laps
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        playPauseButton.rx.tap
            .bind(to: viewModel.playPauseTapped)    // .bind使得点击按钮时，viewModel的playPauseTapped会执行
            .disposed(by: disposeBag)
        
        lapResetButton.rx.tap
            .bind(to: viewModel.lapResetTapped)
            .disposed(by: disposeBag)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        disposeBag = DisposeBag()
    }
    
    @objc func handleAppTermination() {
        viewModel.saveData()
    }
    
    
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.laps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 手动创建
        let identifier: String = "lapCell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: identifier)
        }
        if let cell = cell {
            cell.textLabel?.text = "Lap \(self.laps.count - indexPath.row)"
            cell.detailTextLabel?.text = self.laps[self.laps.count - indexPath.row - 1]
        }
        
        return cell!
    }
}
