//
//  ViewController.swift
//  AVFoundationCamra
//
//  Created by miyazawaryohei on 2020/10/11.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    
    @IBOutlet var previewView: UIView!
    @IBOutlet var shutterButton: UIButton!
    
    var session = AVCaptureSession()
    var photoOutputObj = AVCapturePhotoOutput()
    let notification = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //セッション実行中ならば中断する
        guard !session.isRunning else {
            return
        }
        //シャッターボタンを有効にする
        shutterButton.isEnabled = true
        
        //入出力の設定
        setupInputOutput()
        //プレビューレイヤの設定
        setPreviewLayer()
        //セッションの開始
        session.startRunning()
        //デバイスが回転したときに通知するイベントハンドラを設定する
        notification.addObserver(self, selector: #selector(self.changedDeviceOrientation(_ :)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let captureSetting = AVCapturePhotoSettings()
        captureSetting.flashMode = .auto
        captureSetting.isAutoStillImageStabilizationEnabled = true
        captureSetting.isHighResolutionPhotoEnabled = false
        //キャプチャのイメージ処理はデリゲートに任せる
        photoOutputObj.capturePhoto(with: captureSetting, delegate: self)
        
        
    }
    
    func setupInputOutput(){
        //解像度の指定
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        //入力の設定
        do {
            let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
            
            //入力元
            let input = try AVCaptureDeviceInput(device: device!)
            if session.canAddInput(input){
                session.addInput(input)
            }else{
                print("セッションに入力を追加できなかった")
                return
            }
        } catch let error as NSError {
            print("カメラが使えない\(error.description)")
            //カメラのプライバシー設定を開くためのアラートを表示する
            showAlert(appName: "カメラ")
            return
        }
    }
    //プライバシー認証のアラートを表示する
    func showAlert(appName:String){
        let aTitle = appName + "のプライバシー認証"
        let aMessage = "設定＞プライバシー＞" + appName + "でご利用を許可してください"
        let alert = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        //許可しないボタン（シャッターボタンを利用できなくする）
        alert.addAction(UIAlertAction(title: "許可しない", style: .default, handler: { action in
            self.shutterButton.isEnabled = false
        })
        )
        
        //設定を開くボタン
        alert.addAction(UIAlertAction(title: "設定を開く", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        })
        )
        //アラートを表示する
        self.present(alert, animated: true, completion: nil)
    }
    
    func setPreviewLayer(){
        //プレビューレイヤを作る
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        //previewViewに追加する
        previewView.layer.addSublayer(previewLayer)
    }
    
    @objc func changedDeviceOrientation(_ notification :Notification) {
        //photoOutputObj.connectionの回転向きをデバイスと合わせる
        if let photoOutputConection = self.photoOutputObj.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait :
                photoOutputConection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                photoOutputConection.videoOrientation = .landscapeRight
            default:
                break
            }
            
        }
        
    }
    
}

//デリゲート部分を拡張する
extension ViewController:AVCapturePhotoCaptureDelegate {
    //映像をキャプチャする
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        //Dataを取り出す
        guard let photoData = photo.fileDataRepresentation() else{
            return
        }
        //Dataから写真のイメージを作る
        if let stillImage = UIImage(data: photoData){
            //アルバムに追加する
            UIImageWriteToSavedPhotosAlbum(stillImage, self,
                                           #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    //アルバム追加にエラーがあったかどうか
    @objc func image(_image: UIImage, didFinishSavingWithError error: NSError?, cotextInfo: UnsafeRawPointer) {
        if let error = error {
            //エラー表示
            let alert = UIAlertController(title: "アルバムへの追加エラー",
                                          message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }else{
            print("アルバムへの追加 OK")
        }
    }
}
