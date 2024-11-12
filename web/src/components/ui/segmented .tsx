import { cn } from '@/lib/utils';
import * as React from 'react';
export declare type SegmentedValue = string | number;
export declare type SegmentedRawOption = SegmentedValue;
export interface SegmentedLabeledOption {
  className?: string;
  disabled?: boolean;
  label: React.ReactNode;
  value: SegmentedRawOption;
  /**
   * html `title` property for label
   */
  title?: string;
}
declare type SegmentedOptions = (SegmentedRawOption | SegmentedLabeledOption)[];
export interface SegmentedProps
  extends Omit<React.HTMLProps<HTMLDivElement>, 'onChange'> {
  options: SegmentedOptions;
  defaultValue?: SegmentedValue;
  value?: SegmentedValue;
  onChange?: (value: SegmentedValue) => void;
  disabled?: boolean;
  prefixCls?: string;
  direction?: 'ltr' | 'rtl';
  motionName?: string;
}

export function Segmented({ options, value, onChange }: SegmentedProps) {
  return (
    <div className="flex items-center rounded-sm p-1 gap-2 bg-zinc-200">
      {options.map((option) => {
        const isObject = typeof option === 'object';
        const actualValue = isObject ? option.value : option;

        return (
          <div
            key={actualValue}
            className={cn(
              'inline-flex items-center px-2 py-1 text-sm font-medium rounded-sm cursor-pointer',

              { 'bg-indigo-400': value === actualValue },
            )}
            onClick={() => onChange?.(actualValue)}
          >
            {isObject ? option.label : option}
          </div>
        );
      })}
    </div>
  );
}