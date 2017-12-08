# debian_webasm_webdnn

　DNNモデルをWebAssemblyバイナリへコンパイルできるWEBDNNのdockerイメージ

## Requirement
- Docker
    - もしOSがWindows10 Proなら、Docker for Windowsを推奨

## Usage
1. カレントディレクトリを変換したいDNNモデルファイルのあるディレクトリへ移動
1. Dockerイメージを実行
    - 実行時に作成されたコンテナは終了時に廃棄
    - カレントディレクトリをコンテナの/srcにバインド

```
docker pull lilacs2039/debian_webasm_webdnn
docker run --rm -v "$(pwd):/src" -it lilacs2039/debian_webasm_webdnn
```

３. DNNモデルをwebassembly形式へ変換
    - 適宜、モデル名（↓のresnet50.h5）・input_shapeを変更のこと

```
python /webdnn/bin/convert_keras.py resnet50.h5 --input_shape '(1,224,224,3)' --out output --backend webassembly
```

## License
Apache License 2.0
