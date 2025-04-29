//
//  StopwatchViewModel.swift
//  testMVVM
//
//  Created by colin.qin on 2025/4/28.
//


import RxSwift
import RxCocoa

class StopwatchViewModel {

    private let mainStopwatch = Stopwatch()
    private let lapStopwatch = Stopwatch()
    private let disposeBag = DisposeBag()
    
    // MARK: - Outputs
    var mainTime: Driver<String> {
        return mainTimeSubject.asDriver()
    }
    var lapTime: Driver<String> {
        return lapTimeSubject.asDriver()
    }
    var laps: Driver<[String]> {
        return lapsSubject.asDriver()
    }
    var isRunning: Driver<Bool> {
        return isRunningSubject.asDriver()
    }
    var lapButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(mainTimeSubject.asDriver(), isRunningSubject.asDriver())
            .map { $0 != "00:00.00" || $1 }
    }
    var lapButtonTitle: Driver<String> {
        return Driver.combineLatest(mainTimeSubject.asDriver(), isRunningSubject.asDriver())
            .map { $0 == "00:00.00" || $1 ? "Lap" : "Reset" }
    }
    var playButtonTitle: Driver<String> {
        return isRunningSubject.asDriver()
            .map { $0 ? "Stop" : "Start" }
    }
    var playButtonColor: Driver<UIColor> {
        return isRunningSubject.asDriver()
            .map { $0 ? .systemRed : .systemGreen }
    }
    
    // MARK: - Inputs
    let playPauseTapped = PublishSubject<Void>()
    let lapResetTapped = PublishSubject<Void>()
    
    private let mainTimeSubject = BehaviorRelay<String>(value: "00:00.00")
    private let lapTimeSubject = BehaviorRelay<String>(value: "00:00.00")
    private let lapsSubject = BehaviorRelay<[String]>(value: [])
    private let isRunningSubject = BehaviorRelay<Bool>(value: false)
    
    private let lapsKey = "savedLaps"
    private let mainTimeKey = "mainTimer"
    private let lapTimeKey = "lapTimer"
    
    init() {
        setupTimer()
        setupBindings()
        loadData()
    }
    
    private func setupTimer() {
        // 创建一个每35毫秒发射一个递增值(Int)的Observable
        Observable<Int>.interval(.milliseconds(35), scheduler: MainScheduler.instance)
            .withLatestFrom(isRunningSubject)
            .filter { $0 }  // 当isRunning为true时继续
            .subscribe(onNext: { [weak self] _ in // _为发射的int值
                self?.updateTimers()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateTimers() {
        mainTimeSubject.accept(updateTimer(mainStopwatch))
        lapTimeSubject.accept(updateTimer(lapStopwatch))
    }
    
    private func setupBindings() {
        playPauseTapped
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.isRunningSubject.accept(!self.isRunningSubject.value)
            })
            .disposed(by: disposeBag)
        
        lapResetTapped
            .withLatestFrom(isRunningSubject)
            .subscribe(onNext: { [weak self] isRunning in
                guard let self = self else { return }   // 后续有多个操作需要保持self的强引用
                if isRunning {  // lap
                    var currentLaps = self.lapsSubject.value
                    currentLaps.append(self.lapTimeSubject.value)
                    self.lapsSubject.accept(currentLaps)
                } else {    // reset
                    self.lapsSubject.accept([])
                    self.mainTimeSubject.accept("00:00.00")
                    self.resetTimer(mainStopwatch)
                }
                self.lapTimeSubject.accept("00:00.00")
                self.resetTimer(lapStopwatch)
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func resetTimer(_ stopwatch: Stopwatch) {
        stopwatch.timer.invalidate()
        stopwatch.counter = 0.0
    }
    
    func updateTimer(_ stopwatch: Stopwatch) -> String {
        stopwatch.counter = stopwatch.counter + 0.035
        
        var minutes: String = "\((Int)(stopwatch.counter / 60))"
        if (Int)(stopwatch.counter / 60) < 10 {
            minutes = "0\((Int)(stopwatch.counter / 60))"
        }
        
        var seconds: String = String(format: "%.2f", (stopwatch.counter.truncatingRemainder(dividingBy: 60)))
        if stopwatch.counter.truncatingRemainder(dividingBy: 60) < 10 {
            seconds = "0" + seconds
        }
        
        return minutes + ":" + seconds
    }
    
    
    // MARK: - Data Persistence
    func saveData() {
        UserDefaults.standard.set(lapsSubject.value, forKey: lapsKey)
        UserDefaults.standard.set(mainTimeSubject.value, forKey: mainTimeKey)
        UserDefaults.standard.set(lapTimeSubject.value, forKey: lapTimeKey)
    }

    func loadData() {
        if let savedLaps = UserDefaults.standard.array(forKey: lapsKey) as? [String] {
            lapsSubject.accept(savedLaps)
            mainTimeSubject.accept(UserDefaults.standard.string(forKey: mainTimeKey)!)
            lapTimeSubject.accept(UserDefaults.standard.string(forKey: lapTimeKey)!)
            
            let mainDigits = mainTimeSubject.value.components(separatedBy: CharacterSet(charactersIn: ":."))
            mainStopwatch.counter = Double(mainDigits[0])! * 60 + Double(mainDigits[1])! + Double(mainDigits[2])! / 100
            let lapDigits = lapTimeSubject.value.components(separatedBy: CharacterSet(charactersIn: ":."))
            lapStopwatch.counter = Double(lapDigits[0])! * 60 + Double(lapDigits[1])! + Double(lapDigits[2])! / 100
        }
    }

    
}
