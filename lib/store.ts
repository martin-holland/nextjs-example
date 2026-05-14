import { configureStore } from "@reduxjs/toolkit";
import productsReducer from "../lib/features/products/productsSlice";

export const makeStore = () => {
  return configureStore({
    reducer: {
      products: productsReducer,
      // future slices go here: cart, user, filters...
    },
  });
};

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
