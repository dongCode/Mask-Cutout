import { Asset } from "expo-asset";
import * as FileSystem from "expo-file-system";
import * as Settings from "expo-settings";
import { useEffect, useState } from "react";
import { Image, Text, View } from "react-native";

export default function App() {
  const [imageUri, setImageUri] = useState("");
  useEffect(() => {
    async function getImageUris() {
      const [maskUri, originalUri] = await Promise.all([
        Asset.fromModule(require("./assets/mask.jpeg")).downloadAsync(),
        Asset.fromModule(require("./assets/origin.png")).downloadAsync(),
      ]);

      // console.log("maskUri", maskUri.localUri, originalUri.localUri);
      Settings.processImages(
        maskUri.localUri as string,
        originalUri.localUri as string,
      );
    }

    getImageUris();
  }, []);

  useEffect(() => {
    const subscription = Settings.addImageListener(({ base64 }) => {
      const uri = `${FileSystem.documentDirectory}processedImage.png`;

      FileSystem.writeAsStringAsync(uri, base64, {
        encoding: FileSystem.EncodingType.Base64,
      })
        .then(() => {
          setImageUri(uri);
        })
        .catch((error) => {
          console.error("Error writing file:", error);
        });
    });

    return () => subscription.remove();
  }, [setImageUri]);

  return (
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
      <Image
        source={require("./assets/origin.png")}
        style={{
          height: 200,
          width: 200,
        }}
      />
      <Image
        source={require("./assets/mask.jpeg")}
        style={{
          height: 200,
          width: 200,
        }}
      />
      {imageUri ? (
        <Image source={{ uri: imageUri }} style={{ width: 200, height: 200 }} />
      ) : (
        <View>
          <Text>拼命加载中...</Text>
        </View>
      )}
    </View>
  );
}
