import "./index.css";
import { FeatureDemo169 } from "./compositions/FeatureDemo169";
import { FeatureDemo916 } from "./compositions/FeatureDemo916";

/**
 * Dos compositions, no veinte: el lienzo es lo que cambia entre ellas.
 * La pieza se elige por `slug` en los props, no creando una composition nueva.
 */
export const RemotionRoot: React.FC = () => (
  <>
    <FeatureDemo916 />
    <FeatureDemo169 />
  </>
);
