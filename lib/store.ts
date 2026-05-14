import { configureStore } from "@reduxjs/toolkit";
import productsReducer from "../lib/features/products/productsSlice";
import cartReducer from "./features/cart/cartslice";

export const makeStore = () => {
  return configureStore({
    reducer: {
      products: productsReducer,
      cart: cartReducer,
      // future slices go here: cart, user, filters...
    },
  });
};

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
